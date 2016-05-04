/*
 * Task.h
 * Read/Write Task
 *
 * Created by Miguel Lastras on Apr 1, 2015
 */

#import "Task.h"

@implementation Task

@synthesize address;
@synthesize size;
@synthesize operation;

- (id) initWithAddress:(unsigned long int)anAddress
                ofSize:(unsigned long int)aSize
             operation:(BOOL)anOperation
{
  self = [super init];
  if( self != nil ){
    address = anAddress;
    size = aSize;
    operation = anOperation;
  }
  return self;
}

- (void) setAddress:(unsigned long int)anAddress
             ofSize:(unsigned long int)aSize
          operation:(BOOL)anOperation
{
  address = anAddress;
  size = aSize;
  operation = anOperation;
}

@end
