/*
 * Disk.h 
 * Unlimited Disk
 * 
 * Created by Miguel Lastras on Feb 25, 2015
 */

#import <Foundation/Foundation.h>
#import "InterfaceProtocol.h"

@interface Disk : NSObject <InterfaceProtocol> {
  NSString *name;
  unsigned long int accessCount;
}

@property (nonatomic) unsigned long int accessCount;

// Public interface
- (id) initWithName:(NSString*)theName;
- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read;
- (void) printCapacity;
- (void) releaseMemory;
@end

