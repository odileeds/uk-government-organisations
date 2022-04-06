(function(root){
	// Version 1.1
	if(!root.OI) root.OI = {};

	function Stepped(opt){
		if(!opt) opt = {};
		if(!opt.id) opt.id = "step";
		if(!opt.width) opt.width = 300;
		this.steps = [];
		var popup = document.getElementById(opt.id);
		this.active = -1;
		var transitioning = false;
		this.transition = function(){
			if(popup.parentNode !== null) popup.style.display = "none";
			return;
		};
		var _obj = this;

		if(!popup){
			popup = document.createElement('div');
			popup.classList.add('popup');
			popup.setAttribute('id',opt.id);
			popup.style.position = 'absolute';
			popup.style.background = opt.background||"black";
			popup.style.border = opt.border||"0px";
			popup.style.color = opt.color||"white";
			popup.style.padding = opt.padding||"1em";
			popup.style.zIndex = 9999;
			popup.style.display = "none";
			popup.style.cursor = "pointer";
			document.body.appendChild(popup);
			popup.addEventListener('click',function(){ _obj.close(); });
		}

		function Step(n,el,txt,placement){
			this.el = el;
			this.html = txt;
			this.placement = placement;
			if(!this.el){
				console.error('No DOM element to attach to.',el);
			}
			var styles = document.createElement('style');
			document.head.appendChild(styles);
			this.open = function(){
				if(transitioning){
					popup.removeEventListener('transitionend',_obj.transition);
					transitioning = false;
				}
				_obj.active = n;
				if(this.el){
					var content = txt;
					if(typeof this.html==="string") content = this.html;
					else if(typeof this.html==="function") content = this.html.call(this,popup,txt);
					popup.innerHTML = content;
					popup.setAttribute('data',n);
					
					console.log(this.html,popup,content)

					// Update the position
					this.position();

					return this;
				}

				return this;
			};
			this.position = function(){
				var domRect = this.el.getBoundingClientRect();
				var x = domRect.x + domRect.width/2 + (window.pageXOffset || document.documentElement.scrollLeft);
				var y = domRect.y + domRect.height/2 + (window.pageYOffset || document.documentElement.scrollTop);
				var t = "";
				var m = "";
				var arrow = "";
				var off = "1.25em";

				switch (this.placement){
					case "left":
						x -= domRect.width/2;
						t = "translate3d(calc(-100% - "+off+"),-50%,0)";
						arrow = "left:100%;top:50%;transform:translate3d(0%,-50%,0);border-top: 1em solid transparent;border-bottom: 1em solid transparent;border-left: 1em solid "+(opt.background||"black")+";border-right:0;";
						break;
					case "right":
						x += domRect.width/2;
						t = "translate3d("+off+",-50%,0)";
						arrow = "left:0%;top:50%;transform:translate3d(-100%,-50%,0);border-top: 1em solid transparent;border-bottom: 1em solid transparent;border-right: 1em solid "+(opt.background||"black")+";";
						break;
					case "top":
						y -= domRect.height/2;
						t = "translate3d(-50%,calc(-100% - "+off+"),0)";
						arrow = "left:50%;top:99.99%;transform:translate3d(-50%,0%,0);border-left: 1em solid transparent;border-right: 1em solid transparent;border-top: 1em solid "+(opt.background||"black")+";border-bottom:0;";
						break;
					case "bottom":
						y += domRect.height/2;
						t = "translate3d(-50%,"+off+",0)";
						arrow = "left:50%;top:0%;transform:translate3d(-50%,-100%,0);border-left: 1em solid transparent;border-right: 1em solid transparent;border-bottom: 1em solid "+(opt.background||"black")+";border-top:0;";
						break;
				}

				popup.style.transform = t;
				popup.style.opacity = "1";
				popup.style.display = "";
				styles.innerHTML = '#'+opt.id+' {filter:drop-shadow(1px 1px 2px rgba(0,0,0,0.5));max-width:'+opt.width+'px;} #'+opt.id+' *:last-child { margin-bottom: 0; max-width: '+opt.width+'px; } #'+opt.id+'::before { content:""; position: absolute; width: 0em; height: 0em; '+arrow+' }';

				if(x - opt.width*0.5 < 0){
					// If the box would go off the left of the screen we adjust the width
					popup.style.width = (x * 1.8)+"px";
				}else if(x + opt.width*0.5 > document.body.clientWidth){
					// If the box would go off the right of the screen we adjust the width
					popup.style.width = (Math.min(opt.width,(document.body.clientWidth - x)*1.8))+"px";
				}else{
					popup.style.width = "";
				}
				popup.style.left = x+"px";
				popup.style.top = y+"px";
			};
			this.close = function(){
				if(_obj.active == n){
					popup.style.opacity = "0";
					_obj.active = -1;
					transitioning = true;
					// Add the transitionend event
					popup.addEventListener('transitionend', _obj.transition);
					// Reset the transition
					popup.style.transition = "all 0.3s ease-in";
				}
			};
			return this;
		}
		this.add = function(el,txt,placement){
			var s = new Step(this.steps.length,el,txt,placement);
			this.steps.push(s);
			return s;
		};
		this.close = function(n){
			if(popup){
				if(typeof n==="number" && n==this.active) this.steps[n].close();
				else if(typeof n!=="number") this.steps[this.active].close();
			}
		};
		this.resize = function(){
			if(this.active >= 0){
				popup.style.transition = "";
				this.steps[this.active].position();
			}
		};
		window.addEventListener('resize', function(){
			_obj.resize();
		});
		return this;
	}
	
	root.OI.Stepped = function(opt){
		return new Stepped(opt);
	};

})(window || this);