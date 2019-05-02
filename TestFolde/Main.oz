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
      Grid GridLife GridScore Toolbar Desc DescLife DescScore Window GridItems
   in
      Toolbar=lr(glue:we tbbutton(text:"Quit" glue:w action:toplevel#close))
      Desc=grid(handle:Grid height:50*10 width:50*10)
      DescLife=grid(handle:GridLife height:100 width:50*2)
      DescScore=grid(handle:GridScore height:100 width:50*2)
      Window={QTk.build td(Toolbar Desc DescLife DescScore)}
      {Window show}

      % configure rows and set headers
      for N in 1..10 do
	 {Grid rowconfigure(N minsize:50 weight:0 pad:5)}
      end
      % configure columns and set headers
      for N in 1..10 do
	 {Grid columnconfigure(N minsize:50 weight:0 pad:5)}
      end
      % configure lifeboard
      {GridLife rowconfigure(1 minsize:50 weight:0 pad:5)}
      {GridLife columnconfigure(1 minsize:50 weight:0 pad:5)}
      {GridLife configure(label(text:"life" width:1 height:1) row:1 column:1 sticky:wesn)}
      for N in 1..2 do
	 {GridLife columnconfigure(N+1 minsize:50 weight:0 pad:5)}
      end
      % configure scoreboard
      {GridScore rowconfigure(1 minsize:50 weight:0 pad:5)}
      {GridScore columnconfigure(1 minsize:50 weight:0 pad:5)}
      {GridScore configure(label(text:"score" width:1 height:1) row:1 column:1 sticky:wesn)}
      for N in 1..2 do
	 {GridScore columnconfigure(N+1 minsize:50 weight:0 pad:5)}
      end
      
      {Grid bind(event:'<KeyPress>'
		 args:[atom('K')]
		 action:proc{$ K}
            {System.show 'KeyPressed'}
			   {System.show K}
			end
		 )}
   end

   {BuildWindow}
end