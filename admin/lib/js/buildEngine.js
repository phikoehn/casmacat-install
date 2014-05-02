// change of language pair

var currentInputExtension = "";
var currentOutputExtension = "";
function changeLanguagePair() {
  var inputExtension = $('[name="input-extension"]').val();
  var outputExtension = $('[name="output-extension"]').val();
  //alert(currentInputExtension + " = " +  inputExtension + " / " + currentOutputExtension + " = " +  outputExtension);
  if (inputExtension == "" || outputExtension == "") {
    // hide
    $('#upload').css('display', 'none');
    $('#corpus-table').css('display', 'none');
  }
  else if (inputExtension != currentInputExtension || currentOutputExtension != outputExtension) {
    if (inputExtension == outputExtension) { 
      // same languages -> hide
      $('#upload').css('display', 'none');
      $('#corpus-table').css('display', 'none');
    }
    else {
      // show and refresh
      $('#upload').css('display', 'table-row');
      $('#corpus-table').css('display', 'table-row');
      refreshCorpusTable();
      $('#public-corpora').html('<a href="javascript:showPublicCorpora();">Public corpora</a>');
    }
    currentInputExtension = inputExtension;
    currentOutputExtension = outputExtension;
  }
}

// upload corpus form

function ajaxFileUpload() {
  $("#loading").ajaxStart(function(){ $(this).show(); })
	       .ajaxComplete(function(){ $(this).hide(); });
  $.ajaxFileUpload({
	url:'/?action=buildEngine&do=upload&input-extension=fr&output-extension=en',
	secureuri:false,
	fileElementId:'fileToUpload',
	dataType: 'xml',
	beforeSend:function() {
	  alert("beforeSend");
	  $("#loading").show();
	},
	complete:function() {
	  //alert("uploaded successfully");
	  refreshCorpusTable()
	  $("#loading").hide();
	},				
	success: function (data, status) {
	  if (typeof(data.error) != 'undefined') {
	    if (data.error != '') {
	      alert(data.error);
	    }
            else {
	      alert(data.msg);
	    }
	  }
	},
	error: function (data, status, e) { alert(e); }
  })
  return false;
}

// upload public corpora

function showPublicCorpora() {
  $('#public-corpora').html("Loading public corpus information... <img src=\"/inspect/spinner.gif\" width=12 height=12>");
  var inputExtension = $('[name="input-extension"]').val();
  var outputExtension = $('[name="output-extension"]').val();
  $.ajax({ url: '/?action=buildEngine&do=public-corpora&input-extension=' + inputExtension + '&output-extension=' + outputExtension,
           method: 'get',
           dataType: 'html',
           success: function(remoteData) {
             $('#public-corpora').html(remoteData);
  }});
}

function uploadPublicCorpus( id, url, name ) {
  $(id).html("loading... <img src=\"/inspect/spinner.gif\" width=12 height=12>");
  var inputExtension = $('[name="input-extension"]').val();
  var outputExtension = $('[name="output-extension"]').val();

  $.ajax({ url: '/?action=buildEngine&do=upload-public&url=' + encodeURIComponent( url ) + '&input-extension=' + inputExtension + '&output-extension=' + outputExtension + '&name=' + encodeURIComponent( name ),
           method: 'get',
           dataType: 'html',
           success: function(remoteData) {
             $(id).html(remoteData);
             refreshCorpusTable();
  }});
}

// setup form to select prior settings

function refreshPriorSettingSelection() {
  var inputExtension = $('[name="input-extension"]').val();
  var outputExtension = $('[name="output-extension"]').val();
  $.ajax({ url: '/?action=buildEngine&do=get-prior-settings&input-extension=' + inputExtension + '&output-extension=' + outputExtension,
           method: 'get',
           dataType: 'json',
           success: function(remoteData) {
             alert('got prior settings: ' + remoteData);
  }});
}

// refresh the table with available corpora

function refreshCorpusTable() {
  $('#corpus-table').css('display', 'table-row');
  var inputExtension = $('[name="input-extension"]').val();
  var outputExtension = $('[name="output-extension"]').val();
  $.ajax({ url: '/?action=buildEngine&do=corpus-table&input-extension=' + inputExtension + '&output-extension=' + outputExtension,
           method: 'get',
           dataType: 'text',
           success: function(remoteData) {
             $("#corpus-table-content").html(remoteData);
             if ($('#have-corpora').length) {
               refreshConfig();
             }
  }});
}

// refresh the configuration settings

function refreshConfig() {
  $('#have-corpora').each(function() {
    $(this).find('td input:checked').each(function () {
      alert(this);
    });
  });

  refreshTuning();
  $('.config').css('display', 'table-row');
}

// get a list of corpora from table

function getCorpusList() {
  var corpusList = [];
  $('#have-corpora > tbody > tr').each(function() {
    var corpus = {};
    corpus.id = $(this).find('.corpus-id').html();
    corpus.name = $(this).find('.corpus-name').html();
    corpus.size = $(this).find('.corpus-size').html();
    corpusList.push( corpus );
  });
  return corpusList;
}

// refresh options for tuning sets

function refreshTuning() {
  corpusList = getCorpusList();
  $("#tuning-corpus").empty();
  $("#evaluation-corpus").empty();
  for(var i=0; i<corpusList.length; i++) {
    corpus = corpusList[i];
    var option = $('<option/>', { value:corpus.id, text:corpus.name });
    $("#tuning-corpus").append( option );
    $("#evaluation-corpus").append( option.clone() );
  }
  guessTuningSelect("#tuning");
  guessTuningSelect("#evaluation");
}

function guessTuningSelect( field ) {
  tuningCorpusId = $("select"+field+"-corpus option").filter(":selected").val();
  var corpusList = getCorpusList();
  for(var i=0; i<corpusList.length; i++) {
    var corpus = corpusList[i];
    if (corpus.id == tuningCorpusId) {
      if (corpus.size >= 4000) {
        $(field+"-select-select").prop("checked", true);
      }
      else {
        $(field+"-select-all").prop("checked", true);
      }
      refreshTuningCount( field );
    }
  }
}

function refreshTuningCount( field ) {
  if ($(field+"-select-select").prop("checked")) {
    $(field+"-count").removeAttr("disabled");
  }
  else {
    $(field+"-count").attr("disabled", 1);
  }
}
