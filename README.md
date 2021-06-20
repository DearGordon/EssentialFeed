# EssentialFeed
[![CI](https://github.com/DearGordon/EssentialFeed/actions/workflows/CI.yml/badge.svg)](https://github.com/DearGordon/EssentialFeed/actions/workflows/CI.yml)

Where I practicing Unit Test

### Load Feed From Remote Use Case 

#### Data: 
- URL

#### Primary course (happy path) :
1. Execute "Load Image Feed" command with above data.
2. System downloads data from the URL.
3. System validates downloaded data.
4. System creates image feed from valid data.
5. System delivers image feed.

#### Invalid data - error course (sad path):
1. System delivers invalid data error.

#### No connectivity - error course (sad path):
1. System delivers connectivity error.

### Load Feed From Cache Use Case

#### Primary course: 
1. Execute "Load Image Feed" command with above data.
2. System fetches feed data from cache.
3. System validates cache is less than seven days old.
4. System creates image feed from cached data.
5. System delivers image feed.

#### Error course (sad path):
1. System deliver error.

#### Expired cache course (sad path):
1. System deletes cache.
2. System delivers no feed images

#### Empty cache course (sad path):
1. System deliver no feed images.

### Cache Feed Use Case

#### Data:
- Image Feed

#### Primary course (happy path) :
1. Execute "Save image Feed" command with above data.
2. System delete old cache data.
3. System encodes image feed.
4. System timestamps the new cache.
5. System saves new cache data.
6. System delivers success message.

#### Deleting error course (sad path):
1. System delivers error.

#### Saving error course (sad path):
1.System delivers error.
