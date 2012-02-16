# Multi File Uploader for sales/force.com #

This tool allows a user to upload multiple files at once to sales/force.com. Progress bars also indicate the status of these uploads. This is done using the HTML5 File API to read a file locally in the browser, split it into chunks, and sends these file chucks to an Apex controller where the file is reconstructed server side.

## How to Use ##

Add the following component to a Visualforce page. Easy!

	<apex:page>
		<!-- Replace parentId attribute with Id of an object that >supports attachments -->
    	<c:fileUpload parentId="003A000000KKSgS"/>
	</apex:page>

## HTML5 File API ##

Here are two great resources to get familiar with the File API:
[https://developer.mozilla.org/en/DOM/FileReader](http://www.html5rocks.com/en/tutorials/file/dndfiles/)
[http://www.html5rocks.com/en/tutorials/file/dndfiles/](http://www.html5rocks.com/en/tutorials/file/dndfiles/)

## Major Caveats ##
This is all cool but here are a few important limitations.

- Currently only works with Firefox and Chrome. Safari support is on the near horizon. Who knows about IE.
- The maximum size of an individual file upload is approximately 1.27MB. This is due to current heap size limits.


## Forking ##

Feel free to send pull requests and fork away but please push your branches back to this repo as you are working. I'm new to this whole github thing but I'm going to guess that I will be fairly picky when it comes to how code is architected and even formatted for that matter. It would totally suck if you put a lot of time into a feature only to have me not merge it into the main branch because it doesn't follow the path and level of quality I'm envisioning for this tool. Push early and often so we can review feature and bounce ideas off each other. 