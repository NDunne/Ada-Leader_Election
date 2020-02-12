with Ada.Text_IO; use Ada.Text_IO;

procedure Leader_Election is

   -- Limit ID range
   type Node_ID is range 1 .. 20;

   -- Combined Msg type
   type Msg_T is record
     L_Chosen   : Boolean;
     challenge   : Node_ID;
   end record;

   -- Protected Object
   protected type Channel is
     entry Send (o_msg:  in Msg_T);
     entry Recv (i_msg: out Msg_T);
   private 
     Msg     : Msg_T;
     Ready   : Boolean := True;
   end Channel;

   -- Object Body
   protected body Channel is
     -- Send on Channel
     entry Send (o_msg:  in Msg_T) 
     when Ready is -- Guard
     begin
       Msg := o_msg;
       Ready := False;
       -- Don't overwrite
     end;

     -- Recieve on Channel
     entry Recv (i_msg: out Msg_T) 
     when not Ready is -- Guard
     begin
       i_msg := Msg;
       Ready := True;
       -- Can overwrite
     end;
   end Channel;

   type Ch_Access is access all Channel;

   -- Declare array of Channel pointers,
   --  indexed by Node_ID type
   Ch_Arr : array (Node_ID) of Ch_Access 
                  := (others => new Channel);

   -- Generalised Task
   task type node (         ID: Node_ID; 
                   Out_Channel: Ch_Access; 
                    In_Channel: Ch_Access );

   type Node_Access is access node;

   task body node is
     Current                : Node_ID := ID;
     Trial                  : Msg_T;
     L_Chosen, Elected : Boolean := False;
   begin

     Out_Channel.Send((Elected, Current));
     while not L_Chosen loop
       In_Channel.Recv(Trial);

       Put_Line (Node_ID'Image (ID) & ": Recv: " & Node_ID'Image (Trial.Challenge) & Boolean'Image(Trial.L_Chosen) );
       
       -- A Leader has been chosen 
       if Trial.L_Chosen then L_Chosen := True; 
       end if;
        
       if not Elected then
        -- It's me
         if Trial.Challenge = ID then 
           Elected := True;
        -- It's not who I thought it was
         elsif Trial.Challenge > Current then 
           Current := Trial.Challenge;
         end if;
        -- Pass on current Leader theory
         Out_Channel.Send((L_Chosen or Elected, Current));
         Put_Line (Node_ID'Image (ID) & ": Sent: " & Node_ID'Image (Current) & Boolean'Image(L_Chosen or Elected) );
       end if;

     end loop;

    -- Declare self the leader. Only 1 node should do this
     if Elected then 
       Put_Line(Node_ID'Image(ID) & " Elected Leader!"); 
     end if;
   end node;

   New_Node : Node_Access;
   -- Initially Previous Node is the last for ring topo
   Prev : Node_ID := Node_ID'last;

begin
   -- Create a node for each ID. Task starts automatically
   for I in Node_ID'Range loop
      New_Node := new Node (I, 
                            Ch_Arr(I), 
                            Ch_Arr(Prev));
      Prev := I;
   end loop;
end Leader_Election;
