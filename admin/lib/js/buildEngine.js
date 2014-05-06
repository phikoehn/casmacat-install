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
    $('.config').css('display', 'none');
  }
  else if (inputExtension != currentInputExtension || currentOutputExtension != outputExtension) {
    if (inputExtension == outputExtension) { 
      // same languages -> hide
      $('#upload').css('display', 'none');
      $('#corpus-table').css('display', 'none');
      $('.config').css('display', 'none');
    }
    else {
      // show and refresh
      $('#upload').css('display', 'table-row');
      $('#corpus-table').css('display', 'table-row');
      refreshCorpusTable();
      $('#public-corpora').html('<a href="javascript:showPublicCorpora();">Public corpora</a>');
      refreshPreviousSettings();
      refreshConfig();
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

function refreshPreviousSettings() {
  var inputExtension = $('[name="input-extension"]').val();
  var outputExtension = $('[name="output-extension"]').val();
  $.ajax({ url: '/?action=buildEngine&do=get-previous-settings&input-extension=' + inputExtension + '&output-extension=' + outputExtension,
           method: 'get',
           dataType: 'json',
           success: function(remoteData) {
             $("#previous-settings").html('Previous setting <select name="previous-settings" id="previous-setting-options" onchange="reUsePreviousSetting();"><option selected="selected" value="0">none</option></select>');
             for (var run in remoteData) {
               var option = $('<option/>', { value:JSON.stringify(remoteData[run]), text:run });
               $("#previous-setting-options").append(option);
             } 
  }});
}

function reUsePreviousSetting() {
  var json = $('select[id=previous-setting-options]').val();
  var setting = $.parseJSON( json );
  for (var parameter in setting) {
    // special case corpus - multiple values
    if (parameter == "corpus") {
      $("input[name='corpus[]']").prop('checked',false);
      for (var i in setting[parameter]) {
        $("input[name='corpus[]'][value=" + setting[parameter][i] + "]").prop('checked','checked');
      }
    }
    // radio buttons
    else if (parameter == "tuning-select") {
      $('input[name=tuning-select][value=' + setting[parameter] + ']').prop('checked','checked');
      refreshDev();
    }
    else if (parameter == "evaluation-select") {
      $('input[name=evaluation-select][value=' + setting[parameter] + ']').prop('checked','checked');
      refreshDev();
    }
    // all others (except the ones to be ignored)
    else if (parameter != "input-extension" &&
             parameter != "output-extension" &&
             parameter != "action" &&
             parameter != "previous-settings" &&
             parameter != "submit-build") {
      $('[name="' + parameter + '"]').val( setting[parameter] );
    }
  }
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
             refreshConfig();
  }});
}

// refresh the configuration settings

function refreshConfig() {
  if ($('#have-corpora').length) {
    refreshTuning();
    $('.config').css('display', 'table-row');
  }
  else {
    $('.config').css('display', 'none');
  }
}

// get a list of corpora from table

function getCorpusList() {
  var corpusList = [];
  $('#have-corpora > tbody > tr').each(function() {
    var corpus = {};
    corpus.id = $(this).find('.corpus-id').html();
    corpus.name = $(this).find('.corpus-name').html();
    corpus.size = parseInt($(this).find('.corpus-size').html());
    corpus.used = $(this).find('.corpus-used').is(':checked');
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
  guessDevSelect("#tuning");
  guessDevSelect("#evaluation");
}

function guessDevSelect( field ) {
  devCorpusId = $(field+"-corpus option").filter(":selected").val();
  var corpusList = getCorpusList();
  for(var i=0; i<corpusList.length; i++) {
    var corpus = corpusList[i];
    if (corpus.id == devCorpusId) {
      if (corpus.size >= 4000) {
        $(field+"-select-select").prop("checked", true);
      }
      else {
        $(field+"-select-all").prop("checked", true);
      }
    }
  }
  refreshDev();
}

function refreshDev() {
  refreshDevField( '#tuning' );
  refreshDevField( '#evaluation' );
}

function refreshDevField( field ) {
  var devCorpusId = $(field+"-corpus option").filter(":selected").val();
  var corpusList = getCorpusList();
  var corpus;
  for(var i=0; i<corpusList.length; i++) {
    if (corpusList[i].id == devCorpusId) {
      corpus = corpusList[i];
    }
  }
  if (!corpus) {
    return;
  }

  // can't have same full corpus for tuning and evaluation
  var alert = "";
  var tuningCorpusId = $("#tuning-corpus option").filter(":selected").val();
  var evaluationCorpusId = $("#evaluation-corpus option").filter(":selected").val();
  if (tuningCorpusId == evaluationCorpusId && 
      ($("#tuning-select-all").prop("checked") || $("#evaluation-select-all").prop("checked"))) {
    alert += "cannot use all of the same corpus for tuning and evaluation</br>";
  }

  // can't have same full corpus as for training
  if ($(field + "-select-all").prop("checked") && corpus.used) {
    alert += "cannot use all of corpus, if also used for training<br/>";
  }

  // can't have too big of a dev corpus
  if ($(field + "-select-all").prop("checked") && corpus.size > 5000) {
    alert += "corpus too large (use max. 3000 segments)<br/>";
  }

  // can't subsample more than there is
  if ($(field + "-select-select").prop("checked") && corpus.size < parseInt($(field + "-count").val())) {
    alert += "cannot select more segments than corpus size (" + corpus.size + ")<br/>";
  }

  // can't subsample more for tuning and evaluation combined than there is
  else if (tuningCorpusId == evaluationCorpusId &&
      $("#tuning-select-select").prop("checked") && $("#evaluation-select-select").prop("checked") &&
      corpus.size < parseInt($("#tuning-count").val()) + parseInt($("#evaluation-count").val())) {
    alert += "cannot select more segments (tuning and evaluation) than corpus size (" + corpus.size + ")<br/>";
  }

  // show alert
  $(field + "-alert").html(alert);

  // enable / disable subsample size selection
  if ($(field+"-select-select").prop("checked")) {
    $(field+"-count").removeAttr("disabled");
  }
  else {
    $(field+"-count").attr("disabled", 1);
  }
}
