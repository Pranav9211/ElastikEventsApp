using event_api.Data;
using event_api.DTOs;
using event_api.Models;
using event_api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace event_api.Services
{
    public class RegistrationService : IRegistrationService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<RegistrationService> _logger;

        public RegistrationService(ApplicationDbContext context, ILogger<RegistrationService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<RegistrationDto>> GetRegistrationFieldsByUserAndEventAsync(Guid userId, Guid eventCustomFieldId)
        {
            try
            {
                var registrationFields = await _context.RegistrationFields
                    .Where(rf => rf.UserId == userId && rf.EventCustomFieldId == eventCustomFieldId)
                    .Include(rf => rf.EventCustomField)
                        .ThenInclude(ecf => ecf.CustomField)
                    .AsNoTracking()
                    .ToListAsync();

                var result = new List<RegistrationDto>();

                foreach (var rf in registrationFields)
                {
                    try
                    {
                        var answers = JsonSerializer.Deserialize<List<AnswerDto>>(rf.Value) ?? new List<AnswerDto>();

                        // Safely access the Questions list (non-navigable, just a property)
                        var questionList = rf.EventCustomField.CustomField.Questions ?? new List<QuestionModel>();

                        // Enrich answers with matching metadata from questionList
                        var enrichedAnswers = questionList
                            .Where(q => answers.Any(a => a.QuestionText == q.QuestionText))
                            .Select(q =>
                            {
                                var answer = answers.First(a => a.QuestionText == q.QuestionText);
                                return new AnswerDto
                                {
                                    QuestionText = q.QuestionText,
                                    QuestionType = q.QuestionType,
                                    Value = answer.Value,
                                    Options = q.Options,
                                    IsRequired = q.IsRequired
                                };
                            })
                            .ToList();

                        result.Add(new RegistrationDto
                        {
                            RegistrationFieldId = rf.RegistrationFieldId,
                            EventCustomFieldId = rf.EventCustomFieldId,
                            EventId = rf.EventCustomField.EventId,
                            FieldName = rf.EventCustomField.CustomField.FieldName,
                            FieldType = rf.EventCustomField.CustomField.FieldType,
                            Answers = enrichedAnswers
                        });
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Error deserializing answers for registration field {RegistrationFieldId}", rf.RegistrationFieldId);
                    }
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting registration fields for user {UserId} and event {EventId}", userId, eventCustomFieldId);
                throw;
            }
        }



        public async Task<RegistrationDto> CreateRegistrationAsync(RegistrationCreateDto dto, Guid userId)
        {
            try
            {
                // First load the EventCustomField with CustomField
                var eventCustomField = await _context.EventCustomFields
                    .Include(ecf => ecf.CustomField)
                    .FirstOrDefaultAsync(ecf => ecf.EventCustomFieldId == dto.EventCustomFieldId);

                if (eventCustomField == null)
                {
                    throw new KeyNotFoundException($"EventCustomField with ID {dto.EventCustomFieldId} not found");
                }
                _logger.LogInformation("Available Questions: {Questions}", string.Join(", ", eventCustomField.CustomField.Questions.Select(q => q.QuestionText)));
                _logger.LogInformation("Submitted Answers: {Answers}", string.Join(", ", dto.Answers.Select(a => a.QuestionText)));


                // Validate answers against questions
                var validationErrors = ValidateAnswers(dto.Answers, eventCustomField.CustomField.Questions);
                if (validationErrors.Any())
                {
                    throw new ValidationException(string.Join("\n", validationErrors));
                }

                // Enrich answers with question metadata before saving
                var enrichedAnswers = eventCustomField.CustomField.Questions
                    .Where(q => dto.Answers.Any(a => a.QuestionText == q.QuestionText))
                    .Select(q =>
                    {
                        var answer = dto.Answers.First(a => a.QuestionText == q.QuestionText);
                        return new AnswerDto
                        {
                            QuestionText = q.QuestionText,
                            QuestionType = q.QuestionType,
                            Value = answer.Value,
                            Options = q.Options,
                            IsRequired = q.IsRequired
                        };
                    })
                    .ToList();

                var answersJson = JsonSerializer.Serialize(enrichedAnswers);

                var existingRegistration = await _context.RegistrationFields
                    .FirstOrDefaultAsync(rf =>
                        rf.EventCustomFieldId == dto.EventCustomFieldId &&
                        rf.UserId == userId);

                if (existingRegistration != null)
                {
                    existingRegistration.Value = answersJson;
                    _context.RegistrationFields.Update(existingRegistration);
                }
                else
                {
                    var registration = new Registration
                    {
                        RegistrationFieldId = Guid.NewGuid(),
                        EventCustomFieldId = dto.EventCustomFieldId,
                        UserId = userId,
                        Value = answersJson
                    };
                    await _context.RegistrationFields.AddAsync(registration);
                }

                await _context.SaveChangesAsync();

                return new RegistrationDto
                {
                    RegistrationFieldId = existingRegistration?.RegistrationFieldId ?? Guid.NewGuid(),
                    EventCustomFieldId = dto.EventCustomFieldId,
                    EventId = eventCustomField.EventId,
                    FieldName = eventCustomField.CustomField.FieldName,
                    FieldType = eventCustomField.CustomField.FieldType,
                    Answers = enrichedAnswers
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating registration for user {UserId}", userId);
                throw;
            }
        }

        private List<string> ValidateAnswers(List<AnswerDto> answers, List<QuestionModel> questions)
        {
            var errors = new List<string>();

            // Normalize question map for quick lookup
            var normalizedQuestionMap = questions
                .ToDictionary(
                    q => q.QuestionText.Trim().ToLower(),
                    q => q
                );

            foreach (var answer in answers)
            {
                var normalizedAnswerText = answer.QuestionText.Trim().ToLower();

                if (!normalizedQuestionMap.TryGetValue(normalizedAnswerText, out var question))
                {
                    errors.Add($"Question not found: {answer.QuestionText}");
                    continue;
                }

                // Validate required
                if (question.IsRequired && string.IsNullOrWhiteSpace(answer.Value))
                {
                    errors.Add($"Answer is required for: {question.QuestionText}");
                }

                // Validate options if applicable
                if (question.Options?.Count > 0 && !string.IsNullOrWhiteSpace(answer.Value))
                {
                    if (!question.Options.Contains(answer.Value))
                    {
                        errors.Add($"Invalid value '{answer.Value}' for question: {question.QuestionText}. Valid options: {string.Join(", ", question.Options)}");
                    }
                }
            }

            // Check if any required questions are missing in the answer list
            var answeredNormalizedTexts = answers.Select(a => a.QuestionText.Trim().ToLower()).ToHashSet();

            var missingRequired = questions
                .Where(q => q.IsRequired && !answeredNormalizedTexts.Contains(q.QuestionText.Trim().ToLower()))
                .Select(q => q.QuestionText);

            if (missingRequired.Any())
            {
                errors.Add($"Missing answers for required questions: {string.Join(", ", missingRequired)}");
            }

            return errors;
        }

    }
}