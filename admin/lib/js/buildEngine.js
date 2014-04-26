
// refresh the table with available corpora

function refreshCorpusTable() {
  $('corpus-table').style.display = 'table-row';
  var inputExtension = $$('[name="input-extension"]').first().value;
  var outputExtension = $$('[name="output-extension"]').first().value;
  new Ajax.Updater('corpus-table-content', '/?action=buildEngine&do=corpus-table&inputExtension=' + inputExtension + '&output-extension=' + outputExtension, { method: 'get', evalScripts: true });
}

// change of language pair

var currentInputExtension = "";
var currentOutputExtension = "";
function changeLanguagePair() {
  var inputExtension = $$('[name="input-extension"]').first().value;
  var outputExtension = $$('[name="output-extension"]').first().value;
  //alert(currentInputExtension + " = " +  inputExtension + " / " + currentOutputExtension + " = " +  outputExtension);
  if (inputExtension == "" || outputExtension == "") {
    // hide
    $('upload').style.display = 'none';
    $('corpus-table').style.display = 'none';
  }
  else if (inputExtension != currentInputExtension || currentOutputExtension != outputExtension) {
    if (inputExtension == outputExtension) { 
      // same languages -> hide
      $('upload').style.display = 'none';
      $('corpus-table').style.display = 'none';
    }
    else {
      // show and refresh
      $('upload').style.display = 'table-row';
    }
    currentInputExtension = inputExtension;
    currentOutputExtension = outputExtension;
  }
}

// upload corpus form

$('submit-upload').observe('click', function() {
  $('upload-status').update('sending data');
});

function uploadComplete() {
  $('upload-status').update('done');
  refreshCorpusTable();
}

function formHandler(event) {
  alert('hey!');
  $('build-form').request({
    onFailure: function() {
      $('upload-status').update('failed');
    },
    onLoading: function() {  
      $('upload-status').update('sending data');  
    },
    onComplete: function(t) {
      refreshCorpusTable();
      $('upload-status').update('done');  
    }
  });
}
