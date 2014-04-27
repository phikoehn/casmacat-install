
// refresh the configuration settings

function refreshConfig() {
  $('#have-corpora').each(function() {
    $(this).find('td input:checked').each(function () {
      alert(this);
    });
  });

  $('.config').css('display', 'table-row');
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
    }
    currentInputExtension = inputExtension;
    currentOutputExtension = outputExtension;
  }
}

// upload corpus form
	function ajaxFileUpload()
	{
		$("#loading")
		.ajaxStart(function(){
			$(this).show();
		})
		.ajaxComplete(function(){
			$(this).hide();
		});

		$.ajaxFileUpload
		(
			{
				url:'/?action=buildEngine&do=upload&input-extension=fr&output-extension=en',
				secureuri:false,
				fileElementId:'fileToUpload',
				dataType: 'xml',
				beforeSend:function()
				{
					alert("beforeSend");
					$("#loading").show();
				},
				complete:function()
				{
					//alert("uploaded successfully");
					refreshCorpusTable()
					$("#loading").hide();
				},				
				success: function (data, status)
				{
					if(typeof(data.error) != 'undefined')
					{
						if(data.error != '')
						{
							alert(data.error);
						}else
						{
							alert(data.msg);
						}
					}
				},
				error: function (data, status, e)
				{
					alert(e);
				}
			}
		)
		
		return false;

	}

