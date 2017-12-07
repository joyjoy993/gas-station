# A rails API-only project.


## Before running

create index by running  
```bundle exec rake db:mongoid:create_indexes RAILS_ENV=development```

## Goal
Given a gps, return address and nearest gas station using google map API.  

GET ```http://localhost:3000/nearest_gas?lat=37.778015&lng=-122.412272```

Response
```
{
    "address": {
        "streetAddress": "1155 Mission Street",
        "city": "San Francisco",
        "state": "CA",
        "postalCode": "94103-1514"
    },
    "nearest_gas_station": {
        "streetAddress": "1298 Howard Street",
        "city": "San Francisco",
        "state": "CA",
        "postalCode": "94103-2712"
    }
}
```

Save query result into local mongoDB and can use this result as caching
```
{ 
    "_id" : ObjectId("5a29a4d5ebf6ff1f52a6103a"), 
    "query_time" : ISODate("2017-12-04T20:30:12.200+0000"), 
    "address" : {
        "streetAddress" : "5536 Klein Ports", 
        "city" : "West Stephon", 
        "state" : "NH", 
        "postalCode" : "77958-2976"
    }, 
    "nearest_gas_station" : {
        "streetAddress" : "199 Wyatt Unions", 
        "city" : "South Marcoton", 
        "state" : "UT", 
        "postalCode" : "39118-8675"
    }, 
    "gps" : [
        -52.262158, 
        -84.992272
    ]
}
```

## About cache
***Note: All caches are only valid before they become stale, assuming all cases below happend before their cached data are stale.**  
### Cases that will hit the cache
1. querying a gps that was queried before, should return cached data.
2. querying a gps A that its nearby gps B was queried before, should return cached gas station address from B and fetch new address data from google api, and also save a document for A.

## Testing detail
Run all testes by ```rspec spec/```

### Controller testing cases
##### NearestGasController
1. invalid lat and lng as parameters, should return error ```422```.
2. invalid parameters(missing lat or lng, extrat params), should return error ```422```.
3. when google service is unavailable, and we can not fetch data from it, should return error ```500```.
4. normal request should return expected result.

### Model testing cases
##### Location
1. validate ```lat``` and ```lng```, if it doesn't pass validation, should include ```Invalid gps pair``` in errors.
2. two pairs of location documents with the same ```gps``` and ```query_time``` can not be saved into database.
3. ```address``` field can not be blank.
4. ```nearest_gas_station``` field can not be blank.

##### GoogleMapApi
1. should raise ```NearestGasErrors::CustomError``` when google service is unavailable.
2. should raise ```NearestGasErrors::GoogleMapApiError``` when google api returns response without ```OK``` status.
3. should correctly parse address components from google api.

##### NearestGasStation
1. normal query should all be saved into database.
2. if query the same gps more than once within stale time, should return cached data and won't create new document in database.
3. if query nearby gps and cached gas_station_address is found, should use the cached gas_station_address and should not hit the google nearby api.
4. if the cached data is stale, should fetch new data from google api and save them into database.

## Improvement progress
- [x] Thin controller, fat model
    1. move logic from controller to model
- [x] DRY
    1. refactor methods and extract helper methods
    2. extracting values from a hash, use some function like map not a case statment
- [x] Error handling
    1. use custom modules to handle error, please check [nearest_gas_errors](/lib/nearest_gas_errors/) folder
- [x] Validation
    1. validate parameters in url, please check [nearest_gas_validators](/lib/nearest_gas_validators/) folder
    2. validate fields before saving data to database
- [x] Testing
    1. Try to cover as many cases as I can, please check [spec](/spec/) folder
- [ ] Documentation

## To be improved