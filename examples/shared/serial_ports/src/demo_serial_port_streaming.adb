------------------------------------------------------------------------------
--                                                                          --
--                    Copyright (C) 2016-2025, AdaCore                      --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of the copyright holder nor the names of its     --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
------------------------------------------------------------------------------

--  **************************************************************************
--  NOTE: THIS PROGRAM REQUIRES THE RAVENSCAR-FULL-* RUNTIME LIBRARIES.
--  Set the scenario variable accordingly.
--  **************************************************************************

--  A demonstration of a higher-level USART interface using streams. In
--  particular, the serial port is presented as a stream type, so these ports
--  can be used with stream attributes to send values of arbitrary types, not
--  just characters or Strings. For this demonstration, however, we simply
--  read an incoming string from the stream (the serial port) and echo it back,
--  surrounding it with single quotes.

--  HOST COMPUTER SIDE:

--  The incoming strings are intended to come from another program, presumably
--  running on the host computer, connected to the target board with a cable
--  that presents a serial port to the host operating system. The "README.md"
--  file associated with this project describes such a cable.

--  Note that, because it uses the stream attributes String'Output and
--  String'Input, which write and read the bounds as well as the characters,
--  you will need to use a program on the host that uses streams to send and
--  receive these String values. The source code and GNAT project file for such
--  a program are in Ada_Drivers_Library/examples/shared/serial_ports/host_app/

--  TARGET BOARD SIDE:

--  This file declares the main procedure for the program running on the target
--  board. It simply echos the incoming strings, forever.

with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
with Serial_IO;
with Peripherals_Streaming; use Peripherals_Streaming;

procedure Demo_Serial_Port_Streaming is
begin
   Serial_IO.Initialize_Hardware (Peripheral);
   Serial_IO.Configure (COM.Device, Baud_Rate => 115_200);
   --  This baud rate selection is entirely arbitrary. Note that you may
   --  have to alter the settings of your host serial port to match this
   --  baud rate, or just change the above to match whatever the host
   --  serial port has set already. An application such as TerraTerm
   --  or RealTerm is helpful.

   loop
      declare
         --  await the next msg from the serial port
         Incoming : constant String := String'Input (COM'Access);
      begin
         --  echo the received msg content
         String'Output (COM'Access, "You sent '" & Incoming & "'");
      end;
   end loop;
end Demo_Serial_Port_Streaming;
