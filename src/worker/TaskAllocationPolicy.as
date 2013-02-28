package worker
{
	public class TaskAllocationPolicy
	{
		/**
		 * 根据顺序分配任务
		 * */
	   public static const ORDER:String = "order";

	   /**
	   * 根据当前任务量最少着优先分配任务
	   * */
	   public static const MINIZE_TASK:String = "minize_task";
		
		
		
		public function TaskAllocationPolicy()
		{
			throw new Error("instanced this class is not supported!");
		}
	}
}