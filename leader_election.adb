with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers.Indefinite_Ordered_Maps;

procedure Leader_Election is

   subtype Node_ID is Natural range 1 .. 20;

   type Msg_T is record
     L_elected   : Boolean;
     challenge   : Node_ID;
   end record;

   protected type Msg_Channel is
     entry Send (o_msg:  in Msg_T);
     entry Recv (i_msg: out Msg_T);
   private 
     Msg     : Msg_T;
     Ready   : Boolean := True;
   end Msg_Channel;

   protected body Msg_Channel is

     entry Send (o_msg:  in Msg_T) 
       when Ready is
     begin
       Msg := o_msg;
       Ready := False;
     end;

     entry Recv (i_msg: out Msg_T)
       when not Ready is
     begin
       i_msg := Msg;
       Ready := True;
     end;

   end Msg_Channel;

   type Channel_Access is access all Msg_Channel;

   Channels_Arr : array (Node_ID) of Channel_Access := (others => new Msg_Channel);

   task type node (ID: Node_ID; Out_Channel: Channel_Access; In_Channel: Channel_Access);

   type Node_Access is access node;

   task body node is
     Current : Node_ID := ID;
     Trial   : Msg_T;
     Leader_Chosen  : Boolean := False;
     Elected        : Boolean := False;
   begin

      Out_Channel.Send((Elected, Current));
      Put_Line (Node_ID'Image (ID) & ": Sent: " & Node_ID'Image (Current) & Boolean'Image(Elected) );
      while not Leader_Chosen loop
        delay 0.2;       
 
        In_Channel.Recv(Trial);

        Put_Line (Node_ID'Image (ID) & ": Recv: " & Node_ID'Image (Trial.Challenge) & Boolean'Image(Trial.L_Elected) );
        
        if Trial.L_Elected then
          Leader_Chosen := True;
        end if;
        
        if not Elected then
 
          if Trial.Challenge = ID and not Elected then 
            Put_Line("ELECT:" & Node_ID'Image(ID));
            Elected       := True;

          elsif Trial.Challenge > Current then Current := Trial.Challenge;
          end if;

          Out_Channel.Send((Leader_Chosen or Elected, Current));
          Put_Line (Node_ID'Image (ID) & ": Sent: " & Node_ID'Image (Current) & Boolean'Image(Leader_Chosen or Elected) );
        end if;

      end loop;
      if Elected then 
        Put_Line(Node_ID'Image(ID) & " Elected Leader!");
      end if;
   end node;

   New_Node : Node_Access;
   Last : Node_ID := Node_ID'last;

begin
   Put_Line ("In main");
   
   for I in Node_ID'Range loop
      New_Node := new Node (I, Channels_Arr(I), Channels_Arr(Last));
      Last := I;
   end loop;
end Leader_Election;
