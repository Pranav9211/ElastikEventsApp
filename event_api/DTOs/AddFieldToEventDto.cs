using System;
using System.Collections.Generic;

namespace event_api.DTOs
{
    public class AddFieldToEventDto
    {
        public Guid EventId { get; set; }
        public List<Guid> FieldIds { get; set; }
        public Guid AdminId { get; set; } 
    }
}
