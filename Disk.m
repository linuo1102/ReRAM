/*
 * Disk.m
 * Unlimited Disk
 *
 * Created by Miguel Lastras on Feb 25, 2015
 */

#import "Disk.h"

@implementation Disk

@synthesize accessCount;

- (id) initWithName:(NSString*)theName
{
  self = [super init];
  if( self != nil ){
    name = theName;
    accessCount = 0;
  }
  return self;
}

- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read
{
  accessCount++;
}

- (void) printCapacity
{
  printf(" -** %s memory capacity: %s  **-\n", [name UTF8String], "Infinite");
}

- (void) releaseMemory
{
  printf("%s accesses: %lu\n", [name UTF8String], accessCount);
  // do nothing ;)
}

@end
