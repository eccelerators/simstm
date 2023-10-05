# SimStm
SimStm is a VHDL testbench designed to facilitate testing using external stimulus files with the ".stm" extension. This testbench, provided by Eccelerators, aims to simplify test script creation by introducing the STM language and providing IDE support through plugins for Visual Studio Code and Eclipse.

## Features and Advantages
SimStm provides the following features and advantages over similar tools:

- Compact and lightweight compared to other solutions like OSSVM.
- Utilizes its own "stm" language and IDE support for rapid test case creation.
- Supports various VHDL simulators due to its nature as a pure VHDL interpreter.
- Simplifies test writing through IDE plugins for Visual Code and Eclipse.

## Installation and Usage of the plugin
Visual Studio Code Plugin
The SimStm Visual Studio Code plugin enhances your testing experience. It provides code highlighting, auto-completion, and other features to expedite test script development. To install the plugin, follow these steps:

### Open Visual Studio Code.
Go to the Extensions Marketplace.  
Search for "SimStm" and install the plugin.  
Create or open a ".stm" test script file.  
Enjoy the IDE support provided by the plugin.  

### Open Eclipse.
Navigate to the eccelerators.com.  
Here you can download the plugin.  
Install this via Eclipse.  
Create or open a ".stm" test script file within your project.  
Leverage the plugin's IDE features to enhance your testing workflow.  


## Test Commands

### Basics

| Command | Parameters | Description | Comment |
|---------|------------|-------------|---------|
| abort | | Abort simulation | |
| break | | Exit a while loop | Future implementation |
| const | [name] [value] | Define a constant | |
| else | | Else statement | |
| elsif | [value] [operation] [value] | Elseif statement | |
| end if | | End statement for if | |
| finish | | Successful end of simulation | |
| if | [value] [operation] [value] | If statement | |
| include | [file] | Include another *.stm file | |
| loop | [num of iterations] | Start a loop | |
| end loop | | End statement for loop | |
| var | [name] [value] | Define a variable | |
| while | [value] [operation] [value] | Start a while loop | Future implementation |
| end while | | End statement for while | |

### Operations

| Command | Parameters | Description | Comment |
|---------|------------|-------------|---------|
| add | [variable] [value] | Add value to variable | |
| and | [variable] [value] | Logical AND | |
| div | [variable] [value] | Divide value | |
| equ | [variable] [value] | Set new value | |
| mul | [variable] [value] | Multiply value | |
| or | [variable] [value] | Logical OR | |
| sub | [variable] [value] | Subtract value | |
| xor | [variable] [value] | Logical XOR | |
| shl | [variable] [value] | Shift left | |
| shr | [variable] [value] | Shift right | |
| ld | [variable] | Logarithmus Dualis | |
| lg | [variable] [value] | Logarithmus | Maybe a future Implementation |
| pwr | [variable] [value] | Variable ** value (power of) | Maybe a future Implementation |
| inv | [variable] | Invert | |

### Signals

| Command | Parameters | Description |
|---------|------------|-------------|
| signal read | [signal number] [store variable] | Read from a signal |
| signal verify | [signal number] [store variable] [match value] [mask] | Verify a signal |
| signal write | [signal number] [value] | Write to a signal |

### Bus

| Command | Parameters | Description |
|---------|------------|-------------|
| bus read | [bus number] [bit width] [address] [store variable] | Read from a bus |
| bus timeout | [bus number] [timeout] | Set a read timeout for a bus |
| bus verify | [bus number] [bit width] [address] [store variable] [match value] [mask] | Verify the read data from a bus |
| bus write | [bus number] [bit width] [address] [value] | Write to a bus |

### File

| Command | Parameters | Description |
|---------|------------|-------------|
| file | [name] [path] | Path to the file |
| line pos | [name] | Get the current line number of a file |
| line read | [name] [variable to store read data] | Read a line from a file and store data in variable |
| line size | [name] | Get the number of lines in a file |
| line seek | [name] [line number] | Seek to a specific line in a file |
| line write | [name] [message] | Write a line to a file |

### Array

| Command | Parameters | Description |
|---------|------------|-------------|
| array | [name] [size] | Define an array, 1 dim with size of [size] |
| array get | [name] [pos] [variable name] | Read a value at the [pos] of the array and store it into a variable |
| array set | [name] [pos] [value] | Write the value at the array [pos] |
| array size | [name] [variable name] | Read the size of the array and store it into a variable |

### Others

| Command | Parameters | Description |
|---------|------------|-------------|
| call | [name] | Call a subroutine |
| return | | Return from a called subroutine or interrupt routine |
| resume | [0 / 1] | Exit simulation on error (default is 1) |
| interrupt | | Define an interrupt subroutine |
| end interrupt | | End statement for interrupt | |
| jump | [label] | Jump to a label |
| label | | Define a new label |
| marker | [marker number] [value] | Set a marker |
| log | [log level] [message] | Print a message |
| verbosity | [number] | Print only messages that are lesser or equal to the log level |
| random | [variable] | Get a random number |
| seed | [seed number A] [seed number B] | Set the seed numbers for the pseudo-random generator |
| proc | | Begin a subroutine |
| end proc | | End statement for proc | |
| trace | [0 / 1] | Enable or disable SimStm trace |
| wait | [ns] | Wait for * ns |


## Example Usage

Here's an example of how SimStm commands can be used in a test script:

### `main.stm`

```stm
equ ReadModifyWriteBus32 0
equ ReadModifyWriteBus16 0
equ ReadModifyWriteBus8 0
equ CmdBus 0
equ SpiFlashBus 0
equ DoubleBufferBus 0

var WaitTimeOut 100000 -- ms

call $SpiControllerIfcInit
call $CellBufferIfcInit

verbosity $INFO_2
trace 0
wait 1000
log $INFO "Main test started"
log $INFO_3 "HwBufferMask: $HwBufferMask"

call $testSpiFlash

log $INFO "Main test finished"
wait 1000
finish

-- includes must be placed at the end of a module
include "DoubleBuffer/StatusReg.stm"
```

### `StatusReg.stm`

```stm
-- global
-- var WaitTimeOut Test.stm
-- var DoubleBufferBus from DoubleBuffer.stm

-- parameter
var StatusRegOperationMVal 0
var StatusRegOperationMValToWaitFor 0
var StatusRegHwBufferMVal 0
var StatusRegHwBufferMValToWaitFor 0

-- intern
var StatusRegTmp0 0

getStatusRegOperationMVal:
proc
	bus read $DoubleBufferBus 32 $StatusRegAddress StatusRegTmp0
	and StatusRegTmp0 $OperationMask
	equ StatusRegOperationMVal $StatusRegTmp0
end proc

getStatusRegHwBufferMVal:
proc
	bus read $DoubleBufferBus 32 $StatusRegAddress StatusRegTmp0
	log $INFO_3 "getStatusRegHwBufferMVal: $StatusRegTmp0"
	and StatusRegTmp0 $HwBufferMask
	log $INFO_3 -- global
-- var WaitTimeOut Test.stm
-- var DoubleBufferBus from DoubleBuffer.stm

-- parameter
var StatusRegOperationMVal 0
var StatusRegOperationMValToWaitFor 0
var StatusRegHwBufferMVal 0
var StatusRegHwBufferMValToWaitFor 0

-- intern
var StatusRegTmp0 0

getStatusRegOperationMVal:
proc
	bus read $DoubleBufferBus 32 $StatusRegAddress StatusRegTmp0
	and StatusRegTmp0 $OperationMask
	equ StatusRegOperationMVal $StatusRegTmp0
end proc

getStatusRegHwBufferMVal:
proc
	bus read $DoubleBufferBus 32 $StatusRegAddress StatusRegTmp0
	log $INFO_3 "getStatusRegHwBufferMVal: $StatusRegTmp0"
	and StatusRegTmp0 $HwBufferMask
	log $INFO_3 "getStatusRegHwBufferMValHwBufferMask: $HwBufferMask"
	log $INFO_3 "getStatusRegHwBufferMValMasked: $StatusRegTmp0"
	equ StatusRegHwBufferMVal $StatusRegTmp0
end proc

waitForStatusRegOperationMVal:
proc
    loop $WaitTimeOut
        wait 1000
        call $getStatusRegOperationMVal
        log $INFO_3 "waitForStatusRegOperationMVal: $StatusRegOperationMVal"
        if $StatusRegOperationMVal = $StatusRegOperationMValToWaitFor
            return
        end if
    end loop
    log $ERROR "waitForStatusRegOperationMVal: $WaitForStatusRegOperationMVal not set within reasonable time"
    abort
end proc

waitForStatusRegHwBufferMVal:
proc
    loop $WaitTimeOut
        wait 1000
        call $getStatusRegHwBufferMVal
        log $INFO_3 "waitForStatusRegHwBufferMVal: $StatusRegHwBufferMVal"
        if $StatusRegHwBufferMVal = $StatusRegHwBufferMValToWaitFor
            return
        end if
    end loop
    log $ERROR "waitForStatusRegHwBufferMVal: $WaitForStatusRegHwBufferMVal not set within reasonable time"
    abort
end proc"getStatusRegHwBufferMValHwBufferMask: $HwBufferMask"
	log $INFO_3 "getStatusRegHwBufferMValMasked: $StatusRegTmp0"
	equ StatusRegHwBufferMVal $StatusRegTmp0
end proc

waitForStatusRegOperationMVal:
proc
    loop $WaitTimeOut
        wait 1000
        call $getStatusRegOperationMVal
        log $INFO_3 "waitForStatusRegOperationMVal: $StatusRegOperationMVal"
        if $StatusRegOperationMVal = $StatusRegOperationMValToWaitFor
            return
        end if
    end loop
    log $ERROR "waitForStatusRegOperationMVal: $WaitForStatusRegOperationMVal not set within reasonable time"
    abort
end proc

waitForStatusRegHwBufferMVal:
proc
    loop $WaitTimeOut
        wait 1000
        call $getStatusRegHwBufferMVal
        log $INFO_3 "waitForStatusRegHwBufferMVal: $StatusRegHwBufferMVal"
        if $StatusRegHwBufferMVal = $StatusRegHwBufferMValToWaitFor
            return
        end if
    end loop
    log $ERROR "waitForStatusRegHwBufferMVal: $WaitForStatusRegHwBufferMVal not set within reasonable time"
    abort
end proc
```

## Prerequisites
To write ".stm" files, we recommend using the provided IDE plugins for Visual Code and Eclipse. For executing the tests, any VHDL simulator like Siemens Questa or GHDL can be used.

## Connecting to the DUT
SimStm offers two ways to interface with the Device Under Test (DUT): dedicated signals and bus systems. The "signal" and "bus" commands are used to interact with these interfaces. Additionally, SimStm provides packages for both signal and bus definitions, allowing easy integration with named objects without requiring extensive modifications to the testbench.

## Licensing
This project is licensed under the Apache License 2.0. You can find a copy of the license in the LICENSE file.