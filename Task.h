/*
 * Task.h 
 * Read/Write Task
 * 
 * Created by Miguel Lastras on Apr 1, 2015
 */

#import <Foundation/Foundation.h>

@interface Task : NSObject {
  unsigned long int address;
  unsigned long int size;
  BOOL operation;
}

@property (nonatomic, readonly) unsigned long int address;
@property (nonatomic, readonly) unsigned long int size;
@property (nonatomic, readonly) BOOL operation;

// Public interface
- (id) initWithAddress:(unsigned long int)anAddress
                ofSize:(unsigned long int)aSize
             operation:(BOOL)anOperation;
- (void) setAddress:(unsigned long int)anAddress 
             ofSize:(unsigned long int)aSize 
          operation:(BOOL)anOperation;
@end

