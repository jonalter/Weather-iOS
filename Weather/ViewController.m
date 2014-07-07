//
//  ViewController.m
//  Weather
//
//  Created by Jonathan Alter
//
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>

@interface ViewController () <CLLocationManagerDelegate, UITextFieldDelegate>

// UI
@property (strong, nonatomic) IBOutlet UITextField *searchField;

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *weatherLabel;
@property (strong, nonatomic) IBOutlet UILabel *tempLabel;
@property (strong, nonatomic) IBOutlet UILabel *humidityLabel;

// Utils
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.searchField.delegate = self;
    
    // Try to get the current location when the view loads
    [self getCurrentLocation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Actions
- (IBAction)searchByLocation:(id)sender {
    [self getCurrentLocation];
}

- (IBAction)search:(id)sender {
    [self getWeatherWithString:self.searchField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.searchField) {
        [textField resignFirstResponder];
        [self getWeatherWithString:self.searchField.text];
        return NO;
    }
    return YES;
}

#pragma mark - CLLocation Methods
- (void)getCurrentLocation
{
    // Create the location manager if this object does not
    // already have one.
    if (nil == self.locationManager)
        self.locationManager = [[CLLocationManager alloc] init];

    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;

    // Set a movement threshold for new events.
    self.locationManager.distanceFilter = 500; // meters

    [self.locationManager startUpdatingLocation];
}

// CLLocationManagerDelegate delegate method
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    // Stop monitoring location once we have one
    [self.locationManager stopUpdatingLocation];
    // Get location
    CLLocation* location = [locations lastObject];
    [self getWeatherWithLocation:location];
}

#pragma mark - API Calls
- (void)getWeatherWithString:(NSString *)queryString
{
    [self makeWeatherRequestWithParams:@{@"q":queryString}];
}

- (void)getWeatherWithLocation:(CLLocation *)location
{
    [self makeWeatherRequestWithParams:@{
                                         @"lat":[NSNumber numberWithDouble:location.coordinate.latitude],
                                         @"lon":[NSNumber numberWithDouble:location.coordinate.longitude]
                                         }];
}

- (void)makeWeatherRequestWithParams:(NSDictionary *)params
{
    NSLog(@"Params: %@", params);
    
    self.nameLabel.text = @"Loading...";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"http://api.openweathermap.org/data/2.5/weather"
      parameters:params
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"JSON: %@", responseObject);
             
             int code = [responseObject[@"cod"] intValue];
             if (code < 200 || code >= 300) {
                 NSString *message = responseObject[@"message"];
                 if (message) {
                     self.nameLabel.text = message;
                 } else {
                     self.nameLabel.text = [NSString stringWithFormat:@"Error code: %d", code];
                 }
                 return;
             }
             
             NSString *name = responseObject[@"name"];
             if ([name length] > 0) {
                 self.nameLabel.text = [NSString stringWithFormat:@"%@, %@", name, responseObject[@"sys"][@"country"]];
             } else {
                 self.nameLabel.text = responseObject[@"sys"][@"country"];
             }
             
             NSDictionary *main = responseObject[@"main"];
             self.weatherLabel.text = [responseObject[@"weather"] objectAtIndex:0][@"description"];
             self.tempLabel.text = [NSString stringWithFormat:@"%@ K", main[@"temp"]];
             self.humidityLabel.text = [NSString stringWithFormat:@"%@%%", main[@"humidity"]];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Error: %@", error);
             
             self.nameLabel.text = error.localizedDescription;
         }];
}

@end
