// -*- mode: C++ -*-
// Time-stamp: "2015-02-25 11:16:59 sb"

/*
  file       logging.asy
  copyright  (c) Sebastian Blatt 2015

  Simple log and warning interface.

 */


void logging_emit(string msg, string file, string marker){
  write(stdout, marker);
  write(stdout, file + ": ");
  write(msg);
}

// Show an info message
void logging_message(string file, string msg){
  logging_emit(msg, file, "* ");
}

// Show a warning
void logging_warning(string file, string msg){
  logging_emit(msg, file, "! ");
}

// Unrecoverable error, abort execution
void logging_abort(string file, string msg){
  logging_emit(msg, file, "!! ");
  abort();
}

// curry with file name for simple per file specialization so that we
// do not have to type the file name all the time.
typedef void log_fc_t(string);
log_fc_t logging_message_fc(string file){
  return new void(string msg) {logging_message(file, msg);};
}

log_fc_t logging_warning_fc(string file){
  return new void(string msg) {logging_warning(file, msg);};
}

log_fc_t logging_abort_fc(string file){
  return new void(string msg) {logging_abort(file, msg);};
}
