# README
## A rails API-only project.
Given a gps, return address and nearest gas station using google map API.

### Before running
***Create index***

run ```bundle exec rake db:mongoid:create_indexes RAILS_ENV=development```

### Function
GET ```http://localhost:3000/nearest_gas?lat=37.778015&lng=-122.412272```

Response
```
{
    "addresses": [{
        "address": {
            "streetAddress": "1161 Mission Street",
            "city": "San Francisco",
            "state": "CA",
            "postalCode": "94103"
        }}, {
        "address": {
            "streetAddress": "1-49 Julia Street",
            "city": "San Francisco",
            "state": "CA",
            "postalCode": "94103"
        }}, {
        "address": {
            "streetAddress": "1188 Mission Street",
            "city": "San Francisco",
            "state": "CA",
            "postalCode": "94103"
        }}
    ],
    nearest_gas_station: {
        "streetAddress": "1298 Howard Street",
        "city": "San Francisco",
        "state": "CA",
        "postalCode": "94103-2712"
    }
}
```

Insert query log into local mongoDB
```
{ 
    "_id" : ObjectId("5a0b63ceebf6ffdac423a2c4"), 
    "lat" : "37.778015", 
    "lng" : "-122.412272", 
    "addresses" : [
        {
            "address" : {
                "streetAddress" : "1161 Mission Street", 
                "city" : "San Francisco", 
                "state" : "CA", 
                "postalCode" : "94103"
            }
        }, 
        {
            "address" : {
                "streetAddress" : "1-49 Julia Street", 
                "city" : "San Francisco", 
                "state" : "CA", 
                "postalCode" : "94103"
            }
        }, 
        {
            "address" : {
                "streetAddress" : "1188 Mission Street", 
                "city" : "San Francisco", 
                "state" : "CA", 
                "postalCode" : "94103"
            }
        }
    ], 
    "nearest_gas_station" : {
        "streetAddress" : "1298 Howard Street", 
        "city" : "San Francisco", 
        "state" : "CA", 
        "postalCode" : "94103-2712"
    }
}
```

### Testing
Run ```rails test test/controllers/nearest_gas_controller_test.rb```

Fail on the second case because of the second problem below.

### Problem
**1. reversing gps**

For the sample gps [37.77801, -122.4119], I sent a query to google map API

```https://maps.googleapis.com/maps/api/geocode/json?latlng=37.77801,-122.4119076&key=AIzaSyAIU_2CxK-fAGA7WLz6AR_6IDBfshuDzvE```

But it returns more than one result where none of them is '1161 Mission St, San Francisco, CA 94103'.

A note from google map API, '***Reverse geocoding is an estimate. The geocoder will attempt to find the closest addressable location within a certain tolerance. If no match is found, the geocoder will return zero results***'. Therefore, reversing a gps will only return some possible addresses. One address is matched to one gps, but one gps is matched to many possible addressed.

And also, I figure out how to get the most precise gps of an address like '1161 Mission St, San Francisco, CA 94103'.

Use Geocoding API

```https://maps.googleapis.com/maps/api/geocode/json?address=1161%20Mission%20St,%20San%20Francisco,%20CA%2094103&key=AIzaSyAIU_2CxK-fAGA7WLz6AR_6IDBfshuDzvE```

And then it will return GPS [37.7779056, -122.4120423]. If I use this GPS in reversing api, it returns '1161 Mission St, San Francisco, CA 94103' in the first element of the result array, so [37.7779056, -122.4120423] should be the most precise GPS of the sample address.

***My solution***

Return all possible addresses in the response:
```
{
    “addresses": [{
        "address": {
            Possible address
        }}, {
        "address": {
            Possible address
        }}, 
        ......
    ],
    "nearest_gas_station”: {
        Address of the nearest gas station
    }
}
```


**2. nearest gas station returned may not be a gas station**

In my [second test case](/test/controllers/nearest_gas_controller_test.rb#L15), '469 7th Ave, New York, NY 10018, gps: [40.75194, -73.9894451]', it fails.

If we use google map API to query gas station nearby with sort by distance, the nearest one will be '1 Pennsylvania Plaza # 1612, New York', but actually it's only a fuel company.

However, if I search the gas station nearby in the google map website, it will return '466 10th Ave, New York, NY 10018', and this is a real gas station.

***Why?***

If we take a look at the response from google map API, we can see that the type of '1 Pennsylvania Plaza # 1612, New York' is indeed 'gas_station'. The fuel company is somehow classified as 'gas_station'.

***My suggestion or TODO***

There's a field called 'name' in google map API, and we can check if its 'name' is one of the gas station brands in USA, such as 'BP', 'Mobil'.


