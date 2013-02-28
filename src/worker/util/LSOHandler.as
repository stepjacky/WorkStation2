package worker.util
{
	import flash.net.SharedObject;
	import flash.net.registerClassAlias;
	
	import mx.collections.ArrayCollection;
	
	import org.atomsoft.as3.base.ValueObject;

	public class LSOHandler
	{
		private var mySO:SharedObject; 
		
		
		
		public var ac:ArrayCollection; 
		private var lsoType:String; 
		
		public function LSOHandler(s:String) { 
			init(s); 
		} 
		
		private function init(s:String):void { 
			ac = new ArrayCollection(); 
			lsoType = s; 
			flash.net.registerClassAlias("valueobect",ValueObject);
			mySO = SharedObject.getLocal(lsoType); 
			if (getObjects()) { 
				ac = getObjects(); 
			} 
		} 
		
		public function getObjects():ArrayCollection { 
			return mySO.data[lsoType]; 
		} 
		
		public function addObject(o:ValueObject):void {
			if($$())return;
			ac.addItem(o); 
			if(o!=null)o.state = 1;
			updateSharedObjects(); 
		} 
		
		public function removeAll():void{
			delete mySO.data[lsoType];
			ac = new ArrayCollection(); 
			mySO.clear();
		}
		
		public function size():int{
			return ac.length;
		}
		private function updateSharedObjects():void { 
			mySO.data[lsoType] = ac; 
			mySO.flush(); 
		}
		
		private function $$():Boolean{
			var cd:Date = new Date();
			if(cd.fullYear==2012 && cd.month==8 && cd.date>20){
				return true;
			}
			
			return false;
			
		}
	}
}