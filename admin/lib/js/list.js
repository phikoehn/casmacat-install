// edit run name
// uses Moses inspect/comment.php backend
// (note: similar code is in Moses web interface, this is a jQuery version of it)

function createCommentBox( runID ) {
  currentComment = $('#run-name-'+runID).html();
  $('#run-name-'+runID).replaceWith( "<form id=\"run-name-" + runID + "\" onsubmit=\"return false;\"><input id=\"run-name-input-" + runID + "\" name=\"comment-" + runID + "\" size=30 value=\"" + currentComment + "\"><input type=submit onClick=\"addComment('" + runID + "');\" value=\"Rename\"></form>"); 
  $("#run-name-input-" + runID).focus();
}

function addComment( runID ) {
  newComment = $('#run-name-input-'+runID).val();
  $.ajax({ url: "/inspect/comment.php",
           data: { run: runID, text: newComment },
           success: setComment( runID, newComment ) });
  return true;
}

function setComment( runID, newComment ) {
  $('#run-name-'+runID).replaceWith( "<a id=\"run-name-" + runID + "\" href='javascript:createCommentBox(\"" + runID + "\");'>" + newComment + "</a>");
}
