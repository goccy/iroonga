# HOW TO INSTALL

this library supports cocoapods.

(1) Write the following line to Podfile
```rb
pod 'Iroonga', :git => 'https://github.com/goccy/iroonga.git'
```

(2) Install by `pod install` command

```
$ pod install
```

# HOW TO USE
```objc
IroongaLocationDatabase *db = [IroongaLocationDatabase createWithName:@"example"];
IroongaLocationTable *table = [db tableWithName:@"Examples" indexColumnName:@"landmark"];
if (!([db isAlreadyCreated] && [table existsTable])) {
  [db drop];
  db    = [IroongaLocationDatabase createWithName:@"example"];
  table = [db createTableWithName:@"Examples"];
  [table createColumnWithName:@"location" withColumnType:IroongaColumnTypeCompressZlib type:IroongaTableKeyTypeWGS84GeoPoint source:@""];
  [table createLocationIndexColumnWithName:@"location" withTargetColumnName:@"landmark"];
  NSString *filePath = [NSString stringWithFormat:@"%@/groonga_data_dump_file.grn", [[NSBundle mainBundle] resourcePath]];
  [table loadDataFromJSONFile:filePath];
}
CLLocationCoordinate2D topLeftPoint     = ...;
CLLocationCoordinate2D bottomRightPoint = ...;
NSArray *landmarks = [table findWithTopLeftPoint:topLeftPoint withBottomRightPoint:bottomRightPoint];
for (NSDictionary *landmark in landmarks) {
    // access to landmark object and get parameter
}
```
