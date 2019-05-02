functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   Browser
   System
define
   BuildWindow
in
%%%%% Build the initial window and set it up (call only once)
   proc{BuildWindow}
      Grid Toolbar Desc Window Handle
   in
      Toolbar=lr(glue:we tbbutton(text:"Quit" glue:w action:toplevel#close) entry(init:"PC Controler" handle:Handle))
      Desc=grid(handle:Grid height:50*10 width:50*10)
      Window={QTk.build td(Toolbar Desc)}
      {Window show}

      % configure rows and set headers
      for N in 1..10 do
	     {Grid rowconfigure(N minsize:50 weight:0 pad:5)}
      end
      % configure columns and set headers
      for N in 1..10 do
	     {Grid columnconfigure(N minsize:50 weight:0 pad:5)}
      end

      
      {Handle bind(event:'<KeyPress>'
		 args:[atom('K')]
		 action:proc{$ K}
            {System.show 'KeyPressed'}
			   {System.show K}
			end
		 )}
   end

   {BuildWindow}
end