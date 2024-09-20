UART Project

Overview:
---------
This project is a UART design implemented in Verilog and built using Xilinx Vivado. The repository contains all the necessary source files and scripts to recreate the project from scratch using the build script.

How to Rebuild the Vivado Project:
----------------------------------
These steps assume that you've cloned the repository to a new location to avoid Vivado trying to regenerate files that already exist.

1. Clone the Repository:
   ----------------------
   Run the following commands in your terminal:
   
   git clone https://github.com/thatguythere98/UART_Project.git
   cd UART_Project

2. Run the Batch Script:
   ---------------------
   - In Windows Explorer, navigate to the project folder where the `build.bat` file is located.
   - Double-click the `build.bat` file to generate the project files. The batch file automatically runs Vivado in batch mode and executes the `build.tcl` script to recreate the project.
   
   The content of `build.bat` is:
   
   C:\Xilinx\Vivado\<version>\bin\vivado.bat -mode batch -source build.tcl
   
3. Open the Generated Project:
   ----------------------------
   Once Vivado has finished generating the project, open the `.xpr` file (the Vivado project file) by double-clicking it in Windows Explorer or from within Vivado.

Alternative Methods to Run the Build Script:
--------------------------------------------
1. **Using the Vivado TCL Console**:
   - From the welcome screen in Vivado, select `Window -> Tcl Console` to open the Tcl console.
   - In the Tcl console, type the following command to change the working directory to the location of the `build.tcl` file:
     
     cd path/to/UART_Project
     
   - Execute the `build.tcl` script by typing:
     
     source build.tcl
     
   - Once the script finishes running, open the `.xpr` file.

2. **Using Vivado's 'Run TCL Script' Option**:
   - Open Vivado, then go to `Tools -> Run Tcl Script...`
   - In the file selection window, navigate to the location of `build.tcl` in the project directory.
   - Select `build.tcl` and run it. Vivado will automatically recreate the project files.
   - Open the generated `.xpr` file once the script completes.

Notes:
------
- Ensure that you have the correct version of Vivado installed. If necessary, update the path in `build.bat` to point to your Vivado installation.
- Make sure the repository is cloned to a new location if rebuilding the project to avoid file conflicts.

Happy building!
