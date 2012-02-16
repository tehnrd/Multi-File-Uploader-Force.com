	var j$ = jQuery.noConflict();
	j$(document).ready(function() {
		//Event listener for click of Upload button
		j$("#uploadButton").click(function(){
			prepareFileUploads();
		});
		
		//Event listener to clear upload details/status bars once upload is complete
		j$("#clear").on('click',function(){
			j$(".upload").remove();
		});
	});
	
	var byteChunkArray; 
	var files;
	var currentFile;
	var $upload;
	var CHUNK_SIZE = 180000; //Must be evenly divisible by 3, if not, data corruption will occur
	var VIEW_URL = '/servlet/servlet.FileDownload?file=';
	//var parentId, you will see this variable used below but it is set in the component as this is a dynamic value passed in by component attribute
	
	//Executes when start Upload button is selected
	function prepareFileUploads(){
		//Get the file(s) from the input field
		files = document.getElementById('filesInput').files;
		
		//Only proceed if there are files selected
		if(files.length == 0){
			alert('Please select a file!');
			return; //end function
		}
		
		//Disable inputs and buttons during the upload process
		j$(".uploadBox input").attr("disabled", "disabled");
		j$(".uploadBox button").attr({
			disabled: "disabled",
			class: "btnDisabled"
		});
	  
		//Build out the upload divs for each file selected
		var uploadMarkup = '';
		for(i = 0; i < files.length; i++){
			//Determine file display size
			if(files[i].size < 1000000){
				var displaySize = Math.floor(files[i].size/1000) + 'K';
			}else{
				var displaySize  = Math.round((files[i].size / 1000000)*10)/10 + 'MB';
			}
			
			//For each file being uploaded create a div to represent that file, includes file size, status bar, etc. data-Status tracks status of upload
			uploadMarkup += '<div class="upload" data-status="pending" data-index="'+i+'">'; //index used to correspond these upload boxes to records in the files array
			uploadMarkup += '<div class="fileName"><span class="name">'+ files[i].name + '</span> - '+ displaySize+ '</div>';
			uploadMarkup += '<div class="percentComplete">0%</div>'
			uploadMarkup += '<div class="clear"/>';
			uploadMarkup += '<div class="statusBar">';
			uploadMarkup += '<div class="statusBarPercent"/>';
			uploadMarkup += '</div>';
			uploadMarkup += '</div>';
		}
		
		//Add markup to the upload box
		j$('.uploadBox').append(uploadMarkup);
		
		//Once elements have been added to the page representing the uploads, start the actual upload process
		checkForUploads();
	}
	
	function checkForUploads(){
		//Get div of the first matching upload element that is 'pending', if none, all uploads are complete
		$upload = j$(".upload:first[data-status='pending']");
		
		if($upload.length != 0){
			//Based on index of the div, get correct file from files array
			currentFile = files[$upload.attr('data-index')];
			
			/*Build the byteChunkArray array for the current file we are processing. This array is formatted as:
			['0-179999','180000-359999',etc] and represents the chunks of bytes that will be uploaded individually.*/
			byteChunkArray = new Array();  
			
			//First check to see if file size is less than the chunk size, if so first and only chunk is entire size of file
			if(currentFile.size <= CHUNK_SIZE){
				byteChunkArray[0] = '0-' + (currentFile.size - 1);
			}else{
				//Determine how many whole byte chunks make up the file,
				var numOfFullChunks = Math.floor(currentFile.size / CHUNK_SIZE); //i.e. 1.2MB file would be 1000000 / CHUNK_SIZE
				var remainderBytes = currentFile.size % CHUNK_SIZE; // would determine remainder of 1200000 bytes that is not a full chunk
				var startByte = 0;
				var endByte = CHUNK_SIZE - 1;
				
				//Loop through the number of full chunks and build the byteChunkArray array
				for(i = 0; i < numOfFullChunks; i++){
					byteChunkArray[i] = startByte+'-'+endByte;
					
					//Set new start and stop bytes for next iteration of loop
					startByte = endByte + 1;
					endByte += CHUNK_SIZE;
				}
				
				//Add the last chunk of remaining bytes to the byteChunkArray
				startByte = currentFile.size - remainderBytes;
				endByte = currentFile.size;
				byteChunkArray.push(startByte+'-'+endByte);
			}
			
			//Start processing the byteChunkArray for the current file, parameter is '' because this is the first chunk being uploaded and there is no attachment Id
			processByteChunkArray('');
			   
		}else{
			//All uploads completed, enable the input and buttons
			j$(".uploadBox input").removeAttr("disabled");
			j$(".uploadBox button").removeAttr("disabled").attr("class","btn");
			
			/*Remove the browse input element and replace it, this essentially removes
			the selected files and helps prevent duplicate uploads*/
			j$("#filesInput").replaceWith('<input type="file" name="file" multiple="true" id="filesInput">');
		}
	}
	
	//Uploads a chunk of bytes, if attachmentId is passed in it will attach the bytes to an existing attachment record
	function processByteChunkArray(attachmentId){
		//Proceed if there are still values in the byteChunkArray, if none, all piece of the file have been uploaded
		if(byteChunkArray.length > 0){
			//Determine the byte range that needs to uploaded, if byteChunkArray is like... ['0-179999','180000-359999']
			var indexes = byteChunkArray[0].split('-'); //... get the first index range '0-179999' -> ['0','179999']
			var startByte = parseInt(indexes[0]); //0
			var stopByte = parseInt(indexes[1]); //179999
			
			//Slice the part of the file we want to upload, currentFile variable is set in checkForUploads() method that is called before this method
			if(currentFile.webkitSlice){
				var blobChunk = currentFile.webkitSlice(startByte , stopByte + 1);
			}else if (currentFile.mozSlice) {
				var blobChunk = currentFile.mozSlice(startByte , stopByte + 1);
			}
			
			//Create a new reader object, part of HTML5 File API
			var reader = new FileReader();
			
			//Read the blobChunk as a binary string, reader.onloadend function below is automatically called after this line
			reader.readAsBinaryString(blobChunk);
			
			//Create a reader.onload function, this will execute immediately after reader.readAsBinaryString() function above;
			reader.onloadend = function(evt){ 
				if(evt.target.readyState == FileReader.DONE){ //Make sure read was successful, DONE == 2
					//Base 64 encode the data for transmission to the server with JS remoting, window.btoa currently on support by some browsers
					var base64value = window.btoa(evt.target.result);
					
					//Use js remoting to send the base64 encoded chunk for uploading
					FileUploadController.attachBlob(parentId,attachmentId,currentFile.name,currentFile.type,base64value,function(result,event){
			
						//Proceed if there were no errors with the remoting call
						if(event.status == true){
							//Update the percent of the status bar and percent, first determine percent complete
							var percentComplete = Math.round((stopByte / currentFile.size) * 100);
							$upload.find(".percentComplete").text(percentComplete + '%');
							$upload.find(".statusBarPercent").css('width',percentComplete + '%');
							
							//Remove the index information from the byteChunkArray array for the piece just uploaded.
							byteChunkArray.shift(); //removes 0 index
							
							//Set the attachmentId of the file we are now processing
							attachmentId = result;
												
							//Call process byteChunkArray to upload the next piece of the file
							processByteChunkArray(attachmentId);
		
						}else{
							//If script is here something broke on the JavasSript remoting call
							//Add classes to reflect error
							$upload.attr('data-status','complete');
							$upload.addClass('uploadError');
							$upload.find(".statusPercent").addClass('statusPercentError');
							$upload.attr('title',event.message);
							
							//Check and continue the next file to upload
							checkForUploads();
						}
					}); 
				}else{
					//Error handling for bad read
					alert('Could not read file');
				}
			};
			
		}else{
			//This file has completed, all byte chunks have been uploaded, set status on the div to complete
			$upload.attr('data-status','complete');
			
			//Change name of file to link of uploaded attachment
			$upload.find(".name").html('<a href="' + VIEW_URL + attachmentId + '" target="_blank">'+currentFile.name+'</a>');
			
			//Call the checkForUploads to find the next upload div that has data-status="incomplete" and start the upload process. 
			checkForUploads();
		}
	}