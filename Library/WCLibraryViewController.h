/**
 * @class WCLibraryViewController
 */

@interface WCLibraryViewController : UITableViewController

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, weak) NSMutableArray *dataSource;

@end
