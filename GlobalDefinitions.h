//
//  GlobalDefinitions.h
//  e-HReRAM
//
//  Created by Miguel Lastras on 4/16/15.
//  Copyright (c) 2015 Miguel Lastras. All rights reserved.
//

#ifndef e_HReRAM_GlobalDefinitions_h
#define e_HReRAM_GlobalDefinitions_h

#define ADDRESS_SPACE 48

// CHANGE THESE TWO ACCORDINGLY
#define HOST_PAGESIZE 4096 // Actual page size of the computer generating the addresses
#define HOST_PAGESIZE_BITS 12

// CHANGE THESE TWO ACCORDINGLY
//#define HRERAM_PAGESIZE 4096  // Page size of the main HReRAM module
//#define HRERAM_PAGESIZE_BITS 12

#define DELTA 20
#define SINGLE 2

#define _S 10.0
#define _R 80.0
#define _CC 90.0
#define _e 1.0
#define _r 50.0
#define _p 0.5

unsigned long int GlobalTime; // time
FILE *inputPipe;
FILE *hitMissCounters;
FILE *memristiveFraction;
FILE *memristiveHitMissCounters;
FILE *savingsFile;

unsigned long int pid;
char processName[256];
bool testMode;
bool deactivationEnabled;
unsigned long int numberOfInstructions;
unsigned long int batchSize;
unsigned long int deactivationPeriod;
unsigned long int analysisPeriod;

struct EnergyBundle
{
  double readEnergy;
  double writeEnergy;
  double deactivationEnergy;
};

#endif
