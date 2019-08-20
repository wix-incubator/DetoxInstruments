/*
	Photoshop script to generate all macOS app icon PNGs
	https://github.com/jessesquires/app-icons-script

	See included README and LICENSE for details.

	Modifications
		Copyright (c) 2014 Jesse Squires
		Copyright (c) 2012 Josh Jones

	Copyright (c) 2010 Matt Di Pasquale
*/

//	Turn debugger on
//	0 is off.
// 	$.level = 1;

var initialPrefs = app.preferences.rulerUnits;

function main() {
	var doc = app.activeDocument;
	if (doc == null) {
		alert("Oh shit!\nSomething is wrong with the file. Make sure it is a valid PNG file.");
		return;
	}

	app.preferences.rulerUnits = Units.PIXELS;

	if (doc.width != doc.height || doc.width < 1024 || doc.height < 1024) {
		alert("What the fuck is this?!\nImage failed validation. Please select a 1:1 sqaure PNG file that is at least 1024x1024.");
		restorePrefs();
		return;
	}

	var beforeAllState = doc.activeHistoryState;

/*
	//	folder selection dialog
	var destFolder = Folder.selectDialog("Choose an output folder.\n*** Warning! ***\nThis will overwrite any existing files with the same name in this folder.");
	if (destFolder == null) {
		// user canceled
		restorePrefs();
		return;
	}
*/
	var destFolder = (new File($.fileName)).parent;

  // var backgroundsSet = doc.layerSets["backgrounds"];
  //   backgroundsSet.remove();

	//	save icons in PNG-24 using Save for Web
	var saveForWeb = new ExportOptionsSaveForWeb();
	saveForWeb.format = SaveDocumentType.PNG;
	saveForWeb.PNG8 = false;
	saveForWeb.transparency = true;

	//	delete metadata
	doc.info = null;

	var icons = [
        {"name": "Icon-512@2x", "size":1024},
        {"name": "Icon-512", "size":512},

        {"name": "Icon-256@2x", "size":512},
        {"name": "Icon-256", "size":256},

        {"name": "Icon-128@2x", "size":256},
        {"name": "Icon-128", "size":128},

        {"name": "Icon-32@2x", "size":64},
        {"name": "Icon-32", "size":32},

        {"name": "Icon-16@2x", "size":32},
        {"name": "Icon-16", "size":16},
	];

	var initialState = doc.activeHistoryState;

	for (var i = 0; i < icons.length; i++) {
		var eachIcon = icons[i];

    var idImgS = charIDToTypeID( "ImgS" );
    var desc2 = new ActionDescriptor();
    var idWdth = charIDToTypeID( "Wdth" );
    var idPxl = charIDToTypeID( "#Pxl" );
    desc2.putUnitDouble( idWdth, idPxl, eachIcon.size );
    var idscaleStyles = stringIDToTypeID( "scaleStyles" );
    desc2.putBoolean( idscaleStyles, true );
    var idCnsP = charIDToTypeID( "CnsP" );
    desc2.putBoolean( idCnsP, true );
    var idIntr = charIDToTypeID( "Intr" );
    var idIntp = charIDToTypeID( "Intp" );
    var idbicubicAutomatic = stringIDToTypeID( "bicubicAutomatic" );
    desc2.putEnumerated( idIntr, idIntp, idbicubicAutomatic );
    executeAction( idImgS, desc2, DialogModes.NO );
    // doc.resizeImage(eachIcon.size, eachIcon.size, 72, ResampleMethod.BICUBICSHARPER);

		var destFileName = eachIcon.name + ".png";

		doc.exportDocument(new File(destFolder + "/" + destFileName), ExportType.SAVEFORWEB, saveForWeb);

		// undo resize
		doc.activeHistoryState = initialState;
	}

	doc.activeHistoryState = beforeAllState

	restorePrefs();
}

function restorePrefs() {
	app.preferences.rulerUnits = initialPrefs;
}

main();

