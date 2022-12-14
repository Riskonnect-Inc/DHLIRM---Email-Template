var userinput, olat, olng = "";
var locationset = new Array();

//Calculate geocode distance functions
var GeoCodeCalc = {};
GeoCodeCalc.EarthRadiusInMiles = 3956.0;
GeoCodeCalc.EarthRadiusInKilometers = 6367.0;
GeoCodeCalc.ToRadian = function(v) { return v * (Math.PI / 180);};

GeoCodeCalc.DiffRadian = function(v1, v2) {
return GeoCodeCalc.ToRadian(v2) - GeoCodeCalc.ToRadian(v1);
};

GeoCodeCalc.CalcDistance = function(lat1, lng1, lat2, lng2, radius) {
return radius * 2 * Math.asin( Math.min(1, Math.sqrt( ( Math.pow(Math.sin((GeoCodeCalc.DiffRadian(lat1, lat2)) / 2.0), 2.0) + Math.cos(GeoCodeCalc.ToRadian(lat1)) * Math.cos(GeoCodeCalc.ToRadian(lat2)) * Math.pow(Math.sin((GeoCodeCalc.DiffRadian(lng1, lng2)) / 2.0), 2.0) ) ) ) );
};

//Do the geocoding
function GoogleGeocode(apiKey) {
	this.apiKey = apiKey;
	this.geocode = function(address, callbackFunction) {
		$.ajax({
			url: 'http://maps.google.com/maps/geo?output=json&oe=utf8&sensor=true'
					+ '&key=' + this.apiKey + '&q=' + address,
		    dataType: 'jsonp',
			cache: false,
			success: function(data){
				if(data.Status.code==200) {
					var result = {};
					result.longitude = data.Placemark[0].Point.coordinates[0];
					result.latitude = data.Placemark[0].Point.coordinates[1];
					callbackFunction(result);
				} else {
					callbackFunction(null);
				}
			}
		  });
	};
}


//Process form input
$(function() {
	$('#submit-btn').click(function() {
		var userinput = $('form').serialize();
		userinput = userinput.replace("address=","");
		if (userinput == "")
			{
				alert("The input box was blank.");
			}
			
			var g = new GoogleGeocode(apiKey);
			var address = userinput;
			g.geocode(address, function(data) {
				if(data != null) {
					olat = data.latitude;
					olng = data.longitude;
					mapping(olat, olng);
					$(document).ready(function (){window.setTimeout(function(){$('#liId0').trigger('click');}, 10)});
				} else {
					//Unable to geocode
					alert('ERROR! Unable to geocode address');
				}
			});

//Replace spaces in user input
userinput = userinput.replace(" ","+");


	});
});


//Now all the mapping stuff
function mapping(orig_lat, orig_lng){
$(function(){

            //Parse csv with jQuery
			$.ajax({
			type: "GET",
			url: locationsFile,
			dataType: "text/plain",
			success: function(text) { 
           
           		var rows = text.split("\n"); 
                var fields = new Array();
				
				for(var i = 0; i < rows.length; i ++) {           
           		
               		fields = rows[i].split("\t");
					var name = fields[0];
                    var lat = fields[1];
					var lng = fields[2];					
					var address = fields[3];
					var address2 = fields[4];
					var city = fields[5];
					var postal = fields[6];
					var state = fields[7];
					var country = fields[8];
					var distance = GeoCodeCalc.CalcDistance(orig_lat,orig_lng,lat,lng, GeoCodeCalc.EarthRadiusInMiles);               
                
                	//Create the array
					locationset[i] = new Array (distance, name, lat, lng, address, address2, city, state, postal, country, distance);
                
                } 
            					
				//Sort the multi-dimensional array numerically
				locationset.sort(function(a, b) {
					var x = a[0];
					var y = b[0];
					return ((x < y) ? -1 : ((x > y) ? 1 : 0));
				});
				
				//Append the location list to the html for testing
				/*for (x = 0; x <= locationset.length-1; x++)
				{
					$('#distances').append("<br />" + locationset[x] + "<br />");
				}*/
				
				//Create the map with jQuery
				$(function(){ 
					  var map = new GMap2(document.getElementById('map'),{ size: new GSize(1000,500) }); 
					  
					  map.addControl(new GLargeMapControl3D(), new GControlPosition(G_ANCHOR_TOP_RIGHT,new GSize(8,30))) ;
					  map.addControl(new GMapTypeControl());
					  var center_location = new GLatLng(orig_lat,orig_lng); 
					  map.setCenter(center_location, 2); 						  
					   
					  // Create a base icon for all of our markers that specifies the shadow, icon dimensions, etc.
					  var letter;
					  var baseIcon = new GIcon();
					  baseIcon.shadow = "http://www.google.com/mapfiles/shadow50.png";
					  baseIcon.iconSize = new GSize(20, 34);
					  baseIcon.shadowSize = new GSize(37, 34);
					  baseIcon.iconAnchor = new GPoint(9, 34);
					  baseIcon.infoWindowAnchor = new GPoint(9, 2);
					  baseIcon.infoShadowAnchor = new GPoint(18, 25);
					  
					  var markers = new Array(); 
					  for (var y = 0; y <= locationset.length-2; y++) 
					  { 
						 var letter = String.fromCharCode("A".charCodeAt(0) + y);
						 var point = new GLatLng(locationset[y][2], locationset[y][3]);
						 
						 marker = createMarker(point,locationset[y][1], locationset[y][4], locationset[y][5], locationset[y][6], locationset[y][7], locationset[y][8], locationset[y][9], locationset[y][10], letter ); 

						 map.addOverlay(marker);  
						 markers[y] = marker;  
					   }
					   
					   //Create the links that focus on the related marker
					   $("#list").empty();
					   $(markers).each(function(y,marker){ 
							//HTML List to appear next to the map
							var bubbleContent = "<div class=\"loc-name\"><b>" + locationset[y][1] + "</b><\/div> <div class=\"loc-addr\">" + 
							                     locationset[y][4] + "<\/div> <div class=\"loc-addr2\">" + locationset[y][5] + 
							                     "<\/div> <div class=\"loc-addr3\">" + locationset[y][6] + ", " + locationset[y][7] + 
							                     " " + locationset[y][8] + "  " + locationset[y][9] + "<\/div> <div> Distance: " 
							                     + Math.round(locationset[y][0]*10)/10 + " mi<\/div>"
							                     + "<div class=\"lon-lat\">Lat-Lng: " + new GLatLng(locationset[y][2], locationset[y][3]) + "<\/div>";
							                     
							$('<li style="border: 1px dotted #000"/>').html("<div id=\"liId" + y + "\" class=\"loc-name\">" + locationset[y][1] + "<\/div> <div class=\"loc-addr\">" + locationset[y][4] + "<\/div> <div class=\"loc-addr2\">" + locationset[y][5] + "<\/div> <div class=\"loc-addr3\">" + locationset[y][6] + ", " + locationset[y][7] + " " + locationset[y][8] + "  " + locationset[y][9] + "<\/div> <div> Distance: " + Math.round(locationset[y][0]*10)/10 + " mi<\/div>").click(function(){
								displayPoint(marker, y, bubbleContent);
							}).appendTo("#list");	  	
						});
					   
					   //Move the map
						function displayPoint(marker, index, content){ 
						    var moveEnd = GEvent.addListener(map,"moveend", function(){ 
								var markerOffset = map.fromLatLngToDivPixel(marker.getLatLng()); 
								GEvent.removeListener(moveEnd); 
						  	}); 
						  	map.panTo(marker.getLatLng()); 
						  	map.openInfoWindow(marker.getLatLng(), content);
						}
					   
						//Alternate the list colors
						$('#list li').alternate();
				 					
						//Custom marker function - aplhabetical
						function createMarker(point, name, address, address2, city, state, postal, country, distance, letter ) {
						    var letteredIcon = new GIcon(baseIcon);
						    letteredIcon.image = "http://www.google.com/mapfiles/marker"  + ".png";

						    markerOptions = { icon:letteredIcon };
						    var marker = new GMarker(point, markerOptions);
							
							GEvent.addListener(marker,"click", function(){ 
                                var html= "<div class=\"loc-name\"><b>" + name + "</b><\/div> <div class=\"loc-addr\">" + 
                                          address + "<\/div> <div class=\"loc-addr2\">" + address2 + "<\/div> <div class=\"loc-addr3\">" 
                                          + city + ", " + state + " " + postal + "  " + country 
                                          + "<\/div> <div> Distance: " + Math.round(distance*10)/10 + " mi<\/div>"
                                          + "<div class=\"lon-lat\">Lat-Lng: " + point + "<\/div>";
								var elm = document.createElement("div");
								elm.innerHTML = html;
							    
								map.openInfoWindow(marker.getLatLng(), elm);
						  	}); 
	
						  return marker;
						} 					
				});
			}   
		});
	});
}