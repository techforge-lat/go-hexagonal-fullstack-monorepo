package response

import (
	"encoding/json"
)

// MarshalJSON implements custom JSON marshaling for Response
// This ensures that extensions are included at the top level of the JSON
func (r *Response) MarshalJSON() ([]byte, error) {
	// Create a map with all the standard fields
	result := map[string]any{
		"type":   r.TypeURI,
		"status": r.StatusCode,
	}

	// Add optional standard fields if they have values
	if r.TitleText != "" {
		result["title"] = r.TitleText
	}
	if r.DetailText != "" {
		result["detail"] = r.DetailText
	}
	if r.InstanceURI != "" {
		result["instance"] = r.InstanceURI
	}
	if r.DataValue != nil {
		result["data"] = r.DataValue
	}

	// Add all extensions at the top level
	for key, value := range r.Extensions {
		result[key] = value
	}

	return json.Marshal(result)
}

// UnmarshalJSON implements custom JSON unmarshaling for Response
func (r *Response) UnmarshalJSON(data []byte) error {
	// First unmarshal into a generic map
	var raw map[string]any
	if err := json.Unmarshal(data, &raw); err != nil {
		return err
	}

	// Initialize extensions map
	r.Extensions = make(map[string]any)

	// Extract standard fields and remove them from the map
	if typeVal, exists := raw["type"]; exists {
		if typeStr, ok := typeVal.(string); ok {
			r.TypeURI = typeStr
		}
		delete(raw, "type")
	}

	if titleVal, exists := raw["title"]; exists {
		if titleStr, ok := titleVal.(string); ok {
			r.TitleText = titleStr
		}
		delete(raw, "title")
	}

	if detailVal, exists := raw["detail"]; exists {
		if detailStr, ok := detailVal.(string); ok {
			r.DetailText = detailStr
		}
		delete(raw, "detail")
	}

	if statusVal, exists := raw["status"]; exists {
		if statusFloat, ok := statusVal.(float64); ok {
			r.StatusCode = int(statusFloat)
		}
		delete(raw, "status")
	}

	if instanceVal, exists := raw["instance"]; exists {
		if instanceStr, ok := instanceVal.(string); ok {
			r.InstanceURI = instanceStr
		}
		delete(raw, "instance")
	}

	if dataVal, exists := raw["data"]; exists {
		r.DataValue = dataVal
		delete(raw, "data")
	}

	// Everything else goes into extensions
	for key, value := range raw {
		r.Extensions[key] = value
	}

	return nil
}
