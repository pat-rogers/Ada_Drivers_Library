------------------------------------------------------------------------------
--                                                                          --
--                   Copyright (C) 2016-2025, AdaCore                       --
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

--  This file contains the source code for an interactive program to be run on
--  a host computer. It communicates via a host serial port with the streaming
--  demonstration program running on a target board. It uses streams to send
--  and receive strings to/from the target board program for the sake of
--  compatible handling of the bounds. This host program is only intended
--  for the streaming demonstration, not for the other target demonstration
--  programs.

--  This program is to be built with a native machine compiler, not a
--  cross-compiler. The program is known to work on Windows and should work
--  on Linux as well, according to the comments in package GNAT.Communications.

--  The host program requires a serial port to communicate with the serial port
--  on the target board, so a cable is required. One way to do that is to use
--  a special cable that makes a host USB port function like a serial port. The
--  "README.md" file associated with this project describes such a cable, which
--  was used in testing.

--  On the command line invocation you must specify the host serial port number
--  as an integer number (in any base if you use Ada syntax). That number must
--  correspond to the host serial port connected to the target board. No other
--  command line parameters are accepted.

--  During execution, enter a string at the prompt (">") or just hit carriage
--  return if you are ready to quit. If you do enter a string, it will be sent
--  to the target board, along with the bounds. The program running on the
--  target echos it back so this host app will show that response from the
--  board.
--
--  Note that the baud rate for the host serial port is set below, and although
--  arbitrary, must match the value set by the streaming demo program on the
--  target board. That could be an additional host argument in the future. The
--  target serial port is set to eight data bits, no parity, and one stop bit.
--  Those settings are typically what a host serial port uses for defaults, but
--  not necessarily.

with GNAT.IO;                    use GNAT.IO;
with GNAT.Serial_Communications; use GNAT.Serial_Communications;
with Ada.Command_Line;

procedure Host is

   COM             : aliased Serial_Port;
   Selected_Port   : Integer;
   Valid_Selection : Boolean;

   Outgoing : String (1 .. 1024); -- arbitrary
   Last     : Natural range Outgoing'First - 1 .. Outgoing'Last;

   procedure Get_Port_Number
     (Selected_Port : out Integer;
      Valid         : out Boolean);
   --  Get the port number from the command line arguments (only one is
   --  expected), ensuring that the argument is a well-formed integer with
   --  the required range.
   --
   --  Note that it does not check whether a valid argument corresponds to an
   --  existing host serial port. If it does not, GNAT.Serial_Communications
   --  will raise Serial_Error when Open is called.

   ---------------------
   -- Get_Port_Number --
   ---------------------

   procedure Get_Port_Number
     (Selected_Port : out Integer;
      Valid         : out Boolean)
   is
      use Ada.Command_Line;
   begin
      Valid := False;
      Selected_Port := 0;  -- won't be used unless the caller ignores Valid

      if Argument_Count /= 1 then
         Put_Line ("You must specify (only) the number of the COM port to open on this host.");
         Put_Line ("For example, to specify COM3 the invocation would be:");
         Put_Line ("    host 3");
         Put_Line ("The following Windows PowerShell command lists all existing ports:");
         Put_Line ("    [System.IO.Ports.SerialPort]::GetPortNames()");
         return;
      end if;

      Well_Formed : begin
         Selected_Port := Integer'Value (Argument (1));
      exception
         when others =>
            Put_Line ("You must specify a syntactically valid (positive) integer value for the host COM port.");
            return;
      end Well_Formed;

      if Selected_Port < 1 then
         Put_Line ("You must specify a positive number for the host COM port.");
         --  Because function Name from package GNAT.Serial_Communications
         --  requires a positive value.
         return;
      end if;

      Valid := True;
   end Get_Port_Number;

begin
   Get_Port_Number (Selected_Port, Valid_Selection);
   if not Valid_Selection then
      return;
   end if;

   COM.Open (Name (Selected_Port));
   COM.Set (Rate => B115200, Block => False);
   --  The baud rate is arbitrary but must match the selection by the target
   --  board's stream demonstration program. The other target serial port
   --  settings are N81. That stop bit is likley critical to proper function
   --  of the demo.

   loop
      Put ("> ");
      Get_Line (Outgoing, Last);
      exit when Last = Outgoing'First - 1;

      Put_Line ("Sending: '" & Outgoing (1 .. Last) & "'");

      String'Output (COM'Access, Outgoing (1 .. Last));

      declare
         Incoming : constant String := String'Input (COM'Access);
      begin
         Put_Line ("Received from board: " & Incoming);
      end;
   end loop;

   COM.Close;
end Host;
