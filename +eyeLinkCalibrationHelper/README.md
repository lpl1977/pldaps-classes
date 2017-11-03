eyeLinkManager

For now this class manages aspects of use of the EyeLink 1000 video eye tracker from PLDAPS.  As it develops, it may come to replace some aspects of the functions of pds.eyelink toolbox.

EyeLink data includes both samples and events.

The samples data is pruned by PLDAPS to include only five rows:
1.  Sample time, in ms, since eye tracker was activated.  
2.  Sample type--I'm not yet sure what this is  
2.  {Left/Right} pupil diameter  
3.  {Left/Right} horizontal eye position (in pixels)
4.  {Left/Right} vertical eye position (in pixels)

The events data is not pruned and includes 30 rows (from output of EyeLink GetQueuedData?)  
	 1: effective time of event   
	 2: event type   
	 3: read (bits indicating which data fields contain valid data - see eye_data.h.)   
	 4: eye  
	 5: start time  
	 6: end time  
	 7: HEADREF gaze position starting point x  
	 8: HEADREF gaze position starting point y  
	 9: display gaze position starting point x (in pixel coordinates set by screen_pixel_coords command)  
	 10: display gaze position starting point y (in pixel coordinates set by screen_pixel_coords command)  
	 11: starting pupil size (arbitrary units, area or diameter as selected by pupil_size_diameter command)  
	 12: HEADREF gaze position ending point x  
	 13: HEADREF gaze position ending point y  
	 14: display gaze position ending point x (in pixel coordinates set by screen_pixel_coords command)  
	 15: display gaze position ending point y (in pixel coordinates set by screen_pixel_coords command)  
	 16: ending pupil size (arbitrary units, area or diameter as selected by pupil_size_diameter command)  
	 17: HEADREF gaze position average x  
	 18: HEADREF gaze position average y  
	 19: display gaze position average x (in pixel coordinates set by screen_pixel_coords command)  
	 20: display gaze position average y (in pixel coordinates set by screen_pixel_coords command)  
	 21: average pupil size (arbitrary units, area or diameter as selected by pupil_size_diameter command)  
	 22: average gaze velocity magnitude (absolute value) in visual degrees per second  
	 23: peak gaze velocity magnitude (absolute value) in visual degrees per second  
	 24: starting gaze velocity in visual degrees per second  
	 25: ending gaze velocity in visual degrees per second  
	 26: starting angular resolution x in screen pixels per visual degree  
	 27: ending angular resolution x in screen pixels per visual degree  
	 28: starting angular resolution y in screen pixels per visual degree  
	 29: ending angular resolution y in screen pixels per visual degree  
	 30: status (collected error and status flags from all samples in the event (only useful for EyeLink II and EyeLink1000, report CR status and tracking error). see eye_data.h.)  
   
   Event types in row 2:
#define STARTBLINK 3    // pupil disappeared, time only  
#define ENDBLINK   4    // pupil reappeared, duration data  
#define STARTSACC  5        // start of saccade, time only  
#define ENDSACC    6    // end of saccade, summary data  
#define STARTFIX   7    // start of fixation, time only  
#define ENDFIX     8    // end of fixation, summary data  
#define FIXUPDATE  9    // update within fixation, summary data for interval  

#define MESSAGEEVENT 24  // user-definable text: IMESSAGE structure  

#define BUTTONEVENT  25  // button state change:  IOEVENT structure  
#define INPUTEVENT   28  // change of input port: IOEVENT structure  

#define LOST_DATA_EVENT 0x3F   // NEW: Event flags gap in data stream  
