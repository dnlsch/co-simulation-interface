# Co-Simulation Interface

This co-simulation interface enables co-simulation between two distributed servers, each running a specific simulator. The distributed simulators trigger each other and run until a stop condition is reached. The input parameters for the two simulators are exchanged via a git repo.

Attention: The co-simulation interface is still under development and errors may occur.

On each instance, the C-simulation interface is initiated and executed in the file `server.m` which accesses a simulator (here, for example, `simulator.m`).

Feel free to take a look at the example. Adjust the settings to your requirements and run your first co-simulation.


