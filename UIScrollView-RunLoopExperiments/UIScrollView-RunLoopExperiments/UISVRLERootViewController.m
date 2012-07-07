//
//  UISVRLERootViewController.m
//  UIScrollView-RunLoopExperiments
//
//  Created by Evadne Wu on 2/27/12.
//
//  Updated by Jesse Armand with flickr interestingness photos request, to experiment with loading real data
//

#import "UISVRLERootViewController.h"

#import "UISVRLEPhotoTableViewCell.h"
#import "SVProgressHUD.h"

#import "AFNetworking.h"
#import "UIImageView+WebCache.h"

static NSString *const FlickrAPIKey = @"3a90d382bec6c10f96ba132b4344537e";
static NSString *const FlickrAPISecret = @"803f457a5a37235f";
static NSString *const FlickrAPIBaseURL = @"http://api.flickr.com";

static NSString *const FlickrInterestingnessMethod = @"flickr.interestingness.getList";

@interface UISVRLERootViewController ()

@property (nonatomic, readwrite, assign) CFRunLoopObserverRef rlObserver;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong) UINib *cellNib;

- (void) flickrGetInterestingness;
- (void) scheduleRefresh;

@end

@implementation UISVRLERootViewController

@dynamic tableView;
@synthesize rlObserver;
@synthesize photos;
@synthesize page;
@synthesize cellNib;

- (id) init {

	self = [super init];
	if (!self)
		return nil;
	
	self.page = 1;
	self.photos = [NSMutableArray arrayWithCapacity:0];  
  
	self.rlObserver = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
	
#if 1
	
		NSLog(@"Run loop activity %lu (%@)", activity, ((^ (CFRunLoopActivity anActivity) {

			switch (anActivity) {
				
				case kCFRunLoopEntry:
					return @"kCFRunLoopEntry";
				
				case kCFRunLoopBeforeTimers:
					return @"kCFRunLoopBeforeTimers";
				
				case kCFRunLoopBeforeSources:
					return @"kCFRunLoopBeforeSources";
				
				case kCFRunLoopBeforeWaiting:
					return @"kCFRunLoopBeforeWaiting";
				
				case kCFRunLoopAfterWaiting:
					return @"kCFRunLoopAfterWaiting";
				
				case kCFRunLoopExit:
					return @"kCFRunLoopExit";
				
				case kCFRunLoopAllActivities:
					return @"kCFRunLoopAllActivities";
			
			};
			
			return @"(Unknown)";
		
		})(activity)));

#endif
		
	});

	CFRunLoopAddObserver(CFRunLoopGetMain(), self.rlObserver, kCFRunLoopDefaultMode);
	
	return self;

}

- (void) dealloc {
  
	if (rlObserver) {
    
		CFRunLoopRemoveObserver(CFRunLoopGetMain(), rlObserver, kCFRunLoopDefaultMode);
		CFRunLoopObserverInvalidate(rlObserver);
		rlObserver = nil;
    
	}
  
}

- (void) scheduleRefresh {
	
	CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
		
		if (![self isViewLoaded])
			return;
		
		[self updateViews];
		
	});

}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.cellNib = [UINib nibWithNibName:NSStringFromClass([UISVRLEPhotoTableViewCell class]) bundle:nil];
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Load" style:UIBarButtonItemStyleBordered target:self action:@selector(flickrGetInterestingness)];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self flickrGetInterestingness];
}

- (void) updateViews {
	[SVProgressHUD dismiss];
	
	if ([self.photos count] > 0)
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	
	[self.tableView reloadData];
}

#pragma mark - Flickr API

- (NSURL *) flickrPhotoURLFromDictionary:(NSDictionary *)photoDict {
  
	//
	// URL format: http://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}_[mstzb].jpg
	//
	// photo json object: { "id": "6938992897", "owner": "36621592@N06", "secret": "66e7f23f1c", "server": "7042", "farm": 8, "title": "Contigo - with you", "ispublic": 1, "isfriend": 0, "isfamily": 0 }
	//
	
	NSString *photoId = [photoDict objectForKey:@"id"];
	NSString *photoSecret = [photoDict objectForKey:@"secret"];
	NSString *serverId = [photoDict objectForKey:@"server"];
	NSNumber *farmId = [photoDict objectForKey:@"farm"];
	NSString *photoURLString = [NSString stringWithFormat:@"http://farm%@.staticflickr.com/%@/%@_%@_z.jpg", farmId, serverId, photoId, photoSecret];
	
	NSURL *photoURL = [NSURL URLWithString:photoURLString];
	return photoURL;
}

- (void) flickrGetInterestingness {
  
	[SVProgressHUD showWithStatus:@"Loading.." networkIndicator:YES];
	
	// Set the page limit to 10, so it will be loading 10*20 = 200 photos in the end
	
	++self.page;
	
	if (self.page > 10) {  
		self.page = 1;
		return;
	}
	
	NSURL *baseURL = [NSURL URLWithString:FlickrAPIBaseURL];
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
	
	NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:0];
	[parameters setObject:FlickrInterestingnessMethod forKey:@"method"];
	[parameters setObject:FlickrAPIKey forKey:@"api_key"];
	[parameters setObject:@"json" forKey:@"format"];
	[parameters setObject:[NSNumber numberWithInt:1] forKey:@"nojsoncallback"];
	[parameters setObject:[NSNumber numberWithInt:page] forKey:@"page"];
	[parameters setObject:[NSNumber numberWithInt:20] forKey:@"per_page"];
	
	NSURLRequest *request = [httpClient requestWithMethod:@"GET" path:@"/services/rest" parameters:parameters];
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		NSLog(@"%@", JSON);
		
		if ([response statusCode] == 200) {
			NSDictionary *photosDict = [JSON objectForKey:@"photos"];
			if (photosDict != nil) {        
				NSArray *photosArray = [photosDict objectForKey:@"photo"];
				for (NSDictionary *photoDict in photosArray) {
					NSURL *photoURL = [self flickrPhotoURLFromDictionary:photoDict];
					NSString *photoTitle = [photoDict objectForKey:@"title"];
					
					if ( (photoURL != nil) && (photoTitle.length > 0) ) {
						NSDictionary *photo = [NSDictionary dictionaryWithObjectsAndKeys:photoURL, @"url", photoTitle, @"title", nil];
						if (photo != nil) [self.photos addObject:photo];
					}
				}
				
				[self scheduleRefresh];
			}
		}
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		NSLog(@"url: %@, error: %@, %@", [request URL], [error userInfo], JSON);
	}];
	
	[httpClient enqueueHTTPRequestOperation:operation];
}

#pragma mark - UIViewController 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;

	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIScrollView delegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {

	//	NSLog(@"%s %@", __PRETTY_FUNCTION__, scrollView);

}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.tableView.frame.size.width;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return [self.photos count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	NSString *identifier = NSStringFromClass([UISVRLEPhotoTableViewCell class]);
	UISVRLEPhotoTableViewCell *cell = (UISVRLEPhotoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
	if (cell == nil) {
		NSArray *nibObjects = [self.cellNib instantiateWithOwner:self options:nil];
		for (id nibObject in nibObjects) {
			if ([nibObject isKindOfClass:[UISVRLEPhotoTableViewCell class]]) {
				cell = nibObject;
				break;
			}
		}
	}
	
	if ([self.photos count] > indexPath.row) {
		NSDictionary *photo = [self.photos objectAtIndex:indexPath.row];
		
		NSURL *photoURL = [photo objectForKey:@"url"];
		NSString *photoTitle = [photo objectForKey:@"title"];
		
		[cell.photoImageView setImageWithURL:photoURL placeholderImage:nil options:SDWebImageRetryFailed];
		cell.photoTitleLabel.text = photoTitle;
	}
	
	return cell;

}

@end
