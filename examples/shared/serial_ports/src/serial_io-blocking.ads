------------------------------------------------------------------------------
--                                                                          --
--                    Copyright (C) 2015-2025, AdaCore                      --
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

--  This package defines an abstract data type for a "serial port" providing
--  blocking input (Get) and output (Put) procedures. The procedures are
--  considered blocking in that they do not return to the caller until the
--  entire message is received or sent.
--
--  The serial port abstraction is a wrapper around a USART peripheral,
--  described by a value of type Peripheral_Descriptor.
--
--  Polling is used within the procedures to determine when characters are sent
--  and received.

with Message_Buffers;  use Message_Buffers;

package Serial_IO.Blocking is
   pragma Elaborate_Body;

   type Serial_Port (Device : not null access USART) is
     tagged limited private;

   procedure Send
     (This : in out Serial_Port;
      Msg  : not null access Message);
   --  Sends Msg.Length characters of Msg via USART attached to This. Callers
   --  wait until all characters are sent.

   procedure Receive
     (This : in out Serial_Port;
      Msg  : not null access Message)
   with
     Post => Msg.Length <= Msg.Physical_Size and then
             --  At most Msg.Physical_Size characters are included
             (if Msg.Length > 0 then
                Msg.Content_At (Msg.Length) /= Msg.Terminator);
             --  Reception completes if the terminator is received, and the
             --  terminator is not included

   --  Callers to the above wait until all characters are received.

private

   type Serial_Port (Device : access USART) is
     tagged limited null record;

   procedure Await_Send_Ready (This : access USART) with Inline;

   procedure Await_Data_Available (This : access USART) with Inline;

end Serial_IO.Blocking;
