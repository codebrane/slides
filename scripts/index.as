/*
 * Flash MX mini slide show
 *
 * copyright codebrane software 2003
 * www.skyesoft.net
 *
 * v1.5   Removed random_start and added random_slides. The slide show is now truly random as it also
 *        checks to see that random images aren't duplicated
 * v1.3   Fixed a couple of bugs:
 *        Images not showing on the web. It would work locally on the PC but not on the website. Was due
 *        to using an undocumented actionscript function "replace" which didn't return anything. On the
 *        PC, the config file path uses \ whereas on the web it uses /. Was using replace to change \ to
 *        / so get_url_of_slide_show_directory(() would work on both.
 *        Other bug was a delay introduced when morphing was turned on. justStarted = false was in the
 *        wrong place.
 *        Other bug was
 * v1.2   Added morhping due to popular demand. Also added configurable background colour  10/01/2004
 * v1.1   Can now specify what directory the slides are in as well as their filenames 12/07/2003
 * v1.0   Created
 */

// Definitions
var CONFIG_FILE                 = "slides.txt";
var CONFIG_MODE_EASY            = "easy";
var CONFIG_MODE_ADVANCED        = "advanced";
var SAME_DIRECTORY_AS_INDEX_SWF = "SAME";
var WHERE_WE_ARE                = _url;

// Declare our slide variables in global scope
var slideDirectory = "";
var slideFiles = new Array();
var advanced = false;
var morphing = false;
var justStarted = true;
var count = 0;
var primaryImage = image_mc;
var secondaryImage = image2_mc;
var movieToLoadImageInto = image_mc;
var showSlide = true;
var preLoaded = false;

// Random images
var randomImages = false;

// Random start
var randomStart = false;
var started = false;

// Make sure we don't duplicate random images
var previousRandomImage;
 
// Initialise - start at first slide - may be overriden by random_start ...
var slideCount = 1;

// Use this to step through the slides, randomly if required
var slideIndex = 1;

// ...this is where we are on the server...
var whereWeAre = get_url_of_slide_show_directory();

// ...this is the URL of the config file...
var dataFile = whereWeAre + CONFIG_FILE;

// ...hide the slides to start with
primaryImage._alpha = 0;
secondaryImage._alpha = 0;

// Load in the config options
configVars = new LoadVars();
configVars.load (dataFile);
configVars.onLoad = function (success) {
	// If we can't find the config file, flag an error
	if (!success) {
		error_txt.text = "Config Error!";
		error_txt._visible = true;
		return;
	}
	
  // Are we displaying random images?
  if (configVars.random_slides == "yes")
    randomImages = true;
  
  if (configVars.random_start == "yes")
    randomStart = true;
	
  // Change the background colour of the slide show, as defined in the config file
  movieColour = new Color (background_mc);
  backgroundColour = "0x" + configVars.background_colour;
  movieColour.setRGB (backgroundColour);
	
	// Where are the slides stored?
	if (configVars.slides_directory == SAME_DIRECTORY_AS_INDEX_SWF) slideDirectory = whereWeAre;
	else slideDirectory = whereWeAre + configVars.slides_directory + "/";
	
	// Advanced mode?
	if (configVars.mode == CONFIG_MODE_ADVANCED) {
	  advanced = true;

  	// Get the slide names
  	for (c=0; c < configVars.num_slides; c++) {
  	  obj = "slide" + (c+1);
  	  slideFiles[c+1] = configVars[obj];
  	}
  }
	
	// OK, make sure there isn't any error text visible
	error_txt.text = "";
	error_txt._visible = false;
	
	// Flash polling rate is in milliseconds...
	configVars.seconds *= 1000;
	
	// ...and we need a number to increase _alpha but curiously, not to decrease it
	configVars.numFadeRate = new Number (configVars.fade_rate);
	
	// Do we have to morph the image?
	if (configVars.morph == "yes") morphing = true;
	
	// Start the slide show manually...
	slide();
	
	// ...then let Flash take over
	setInterval (slide, configVars.seconds);
}

function slide() {
  count++;
  
	onEnterFrame = function() {
	  // Fade out the first image...
		primaryImage._alpha -= configVars.numFadeRate;
		if (primaryImage._alpha < 0) {
			delete onEnterFrame;
			if (morphing) {
  			if (count == 2) return;
  			if (preLoaded) {
  			  preLoaded = false;
  			  return;
  			}
		  }
			primaryImage.unloadMovie();
    	if (morphing) {
    	  if (!justStarted) {
      		primaryImage._alpha = 0;
      		movieToLoadImageInto = (movieToLoadImageInto == image_mc) ? image2_mc : image_mc;
      		movieToLoadImageInto._alpha = 0;
    	  }
      }
      load_slide();
		}
		
	  // ...and fade in the second
	  if (morphing) {
	    if (secondaryImage._alpha < 100) secondaryImage._alpha += configVars.numFadeRate;
    }
	}
}

function show() {
	onEnterFrame = function() {
	  // Fade in the first image
		primaryImage._alpha += configVars.numFadeRate;
		if (primaryImage._alpha > 100) {
			delete onEnterFrame;
			if (morphing) {
			  secondaryImage._alpha = 0;
  			if (!justStarted) {
  			  preLoaded = true;
  			  movieToLoadImageInto = (movieToLoadImageInto == image_mc) ? image2_mc : image_mc;
    			showSlide = false;
    			load_slide();
  		  }
  			justStarted = false;
		  }
		}
		
		// Fade out the second image
		if (morphing) {
		  if (secondaryImage._alpha > 0) secondaryImage._alpha -= configVars.numFadeRate;
	  }
	}
}

function load_slide() {
	if ((randomStart) && (!started)) {
		slideCount = getRandomNumber();
		started = true;
	}
		
	if (slideCount > configVars.num_slides) {
		slideCount = 1;
	}
	
	if (randomImages)
	  getRandomSlide();
	else
	  slideIndex = slideCount;

  // Load in the first image
	if (advanced) slideFilename = slideDirectory + slideFiles[slideIndex];
	else slideFilename = slideDirectory + slideIndex + ".jpg";
	movieToLoadImageInto.loadMovie (slideFilename);
	
	// We need to load in two images at the start for the morphing
	if (morphing) {
  	if (justStarted) {
    	slideCount++;
    	if (slideCount > configVars.num_slides) {
    		slideCount = 1;
    	}
    	
    	// Load in the second image
    	if (randomImages)
	      getRandomSlide();
	    else
	      slideIndex = slideCount;
	      
    	if (advanced) slideFilename = slideDirectory + slideFiles[slideIndex];
    	else slideFilename = slideDirectory + slideIndex + ".jpg";
    	secondaryImage.loadMovie (slideFilename);
    }
  }
  
  ready = false;
	
	onEnterFrame = function() {
		bytesLoaded = movieToLoadImageInto.getBytesLoaded();
		if (morphing) bytesLoaded2 = secondaryImage.getBytesLoaded();
		
		if ((justStarted) && (morphing)) {
    	if ((bytesLoaded == primaryImage.getBytesTotal()) && (bytesLoaded2 == secondaryImage.getBytesTotal())) {
    	  ready = true;
    	}
	  }
	  else {
      if (bytesLoaded == movieToLoadImageInto.getBytesTotal()) {
        ready = true;
    	}
	  }
		
		if (ready) {
			delete onEnterFrame;
		  if (morphing) {
  			if (justStarted) movieToLoadImageInto = secondaryImage; 
  			if (showSlide) show();
  			else showSlide = true;
		  }
		  else show();
			slideCount++;
		}
	}
}

/* This is interesting. If index.swf is in a directory, say, www.stravaiger.com/slide_show/slides but is referenced from
 * page www.stravaiger.com/slide_show, then the flash player will try to load things from the slide_show directory and
 * not the directory where the flash file actually is. Not very consistent but luckily there is a solution in the
 * form of _url, which tells us the full URL of the swf file.
 */
function get_url_of_slide_show_directory() {
  var url = "";
  
  WHERE_WE_ARE = WHERE_WE_ARE.split ("\\").join ("/");
  
  // Split up the URL - it's of the form http://www.stravaiger.com/bothysoft/index/slides/index.swf
  parts = WHERE_WE_ARE.split ("/");
  noOfParts = parts.length;
  
  // Rebuild it without the filename at the end, i.e. http://www.stravaiger.com/bothysoft/index/slides/
  for (c=0; c < (parts.length - 1); c++) {
    url += parts[c];
    url += "/";
  }
  
  return url;
}

function getRandomSlide() {
  // Choose a random image...
  slideIndex = Math.ceil(Math.random()*configVars.num_slides);
  // ...and make sure it's not the same as the previous random image
  while (slideIndex == previousRandomImage) {
    slideIndex = Math.ceil(Math.random()*configVars.num_slides);
  }
  previousRandomImage = slideIndex;
}

function getRandomNumber() {
  return Math.ceil(Math.random()*configVars.num_slides);
}

