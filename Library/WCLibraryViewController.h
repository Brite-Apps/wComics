/**
 * @class WCLibraryViewController
 */

@interface WCLibraryViewController : UITableViewController

@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) NSMutableArray *dataSource;

@end
