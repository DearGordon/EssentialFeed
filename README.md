# EssentialFeed
[![CI](https://github.com/DearGordon/EssentialFeed/actions/workflows/CI.yml/badge.svg)](https://github.com/DearGordon/EssentialFeed/actions/workflows/CI.yml)

Where I practicing Unit Test

### Cache Feed Use Case

#### Data:
- Feed items

#### Primary course (happy path) :
1. Execute "Save Feed Items" command with above data.
2. System delete old cache data.
3. System encodes feed items.
4. System timestamps the new cache.
5. System saves new cache data.
6. System delivers success message.

#### Deleting error course (sad path):
1. System delivers error.

#### Saving error course (sad path):
1.System delivers error.
