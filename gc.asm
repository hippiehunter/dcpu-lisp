:start
	set j, test_gc_new_enviornment
	set PC, gc_init

; gc_info is layed out as follows
;	- gen1 pos
;	- gen1 alloc info
;		bit flags and resident percent
;		disable promotion (set this flag to prevent promotion if you are performing a mutating construction on an immutable object)
;	- gen1 end
;	- gen2 pos (gen2 end is paripheral start)
;	- allocated-object-list-head
;	- free-object-list-head
;	- perm gen pos
;	- gen2-allocated-object-list-head
;	- perm gen end
:gc_gen1_pos
	dat 0x0000
:gc_gen1_alloc_info
	dat 0x0000
:gc_gen1_end
	dat 0x0000
:gc_gen2_pos
	dat 0x0000
:gc_allocated_object_list_head
	dat 0x0000
:gc_free_object_list_head
	dat 0x0000
:gc_perm_gen_pos
	dat 0x0000
:gc_gen2_allocated_object_list_head
	dat 0x0000
:gc_perm_gen_end
	dat 0x0000
:gc_gen1_grey_list
	dat 0x0000
:gc_gen1_black_list
	dat 0x0000
:gc_gen2_needs_collection
	dat 0x0000

;this is where we can save off registers when we transfer to the GC
;a, b, c, i, j, x, y, z
:gc_transfer_a
	dat 0x0000
:gc_transfer_b
	dat 0x0000
:gc_transfer_c
	dat 0x0000
:gc_transfer_i
	dat 0x0000
:gc_transfer_j
	dat 0x0000
:gc_transfer_x
	dat 0x0000
:gc_transfer_y
	dat 0x0000
:gc_transfer_z
	dat 0x0000

;this is where we can save off registers when doing complex marking, collecting and promotion
:gc_marking_a
	dat 0x0000
:gc_marking_b
	dat 0x0000
:gc_marking_c
	dat 0x0000
:gc_marking_i
	dat 0x0000
:gc_marking_j
	dat 0x0000
:gc_marking_x
	dat 0x0000
:gc_marking_y
	dat 0x0000
:gc_marking_z
	dat 0x0000
:gc_collect_j
	dat 0x0000
:gc_collect_a
	dat 0x0000
:gc_promote_j
	dat 0x0000

;this is the currently executing environment
:gc_current_environment
	dat 0x0000

:gc_mark_dispatch
	dat 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000

:gc_size_dispatch
	dat 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000


;initialize all of the gc structures
:gc_init
	set [gc_gen1_pos], 0xFE00
	set [gc_gen1_alloc_info], 0x0000
	set [gc_gen1_end], 0xFFFF
	set [gc_gen2_pos], static_code_end
	set [gc_allocated_object_list_head], 0x0000
	set [gc_free_object_list_head], 0x0000
	set [gc_perm_gen_pos], 0xC000
	set [gc_gen2_allocated_object_list_head], 0x0000
	set [gc_perm_gen_end], 0xEFFF
	set [gc_gen1_grey_list], 0x0000
	set [gc_gen1_black_list], 0x0000

	set y, gc_mark_dispatch
	set (0x0001 + y), gc_list_mark
	set (0x0002 + y), gc_no_mark ;array
	set (0x0003 + y), gc_no_mark ;string
	set (0x0004 + y), gc_object_list_mark
	set (0x0005 + y), gc_object_array_mark
	set (0x0006 + y), gc_no_mark ;binary tree (not implemented yet)
	set (0x0014 + y), gc_environment_mark

	set y, gc_size_dispatch
	set (0x0001 + y), gc_size_simple
	set (0x0002 + y), gc_size_length ;array
	set (0x0003 + y), gc_size_half_length ;string
	set (0x0004 + y), gc_size_simple
	set (0x0005 + y), gc_size_length
	set (0x0006 + y), gc_size_simple ;binary tree (not implemented yet)
	set (0x0014 + y), gc_size_environment

	set PC, j

;**************************************************************************************************
;***************** gc object size routines *****************************************************
;**************************************************************************************************
:gc_size_simple
	set b, 3 ;tag and two word fields
	set PC, j

:gc_size_length
	set b, 2 ;tag + length field + the length
	set c, [a]
	set c, (0x0001 + c) ;deref to length
	add b, c ;add the length to our static size
	set PC, j
	
:gc_size_half_length
	set b, 2 ;tag + length field + the length
	set c, [a]
	set c, (0x0001 + c) ;deref to length
	div c, 2
	add c, o ;pick up the leftover if there is one
	add b, c ;add the length to our static size
	set PC, j
:gc_size_environment
	set c, [a]
	set b, (0x0005 + c)
	add b, (0x0006 + c)
	add b, 7
	set PC, j
	
;**************************************************************************************************
;***************** gc object marking routines *************************************************
;**************************************************************************************************
:gc_list_mark
	set y,  (0x0002 + b) ;set y to list->next_ptr
	ife y, 0 ;null next_ptr dump out
		set PC, j
	set a, [y] ;deref next_ptr to handle
	set PC, gc_move_to_grey
	
:gc_no_mark
	set PC, j

:gc_object_list_mark
	set [gc_marking_b], b
	set [gc_marking_j], j
	set j, gc_object_list_mark_finished
	set y, (0x0002 + b) ;set y to list->next_ptr
	ife y, 0 ;was a null next_ptr skip it and do the value
		set PC, gc_object_list_mark_finished_next_ptr
	set a, [y]  ;deref next_ptr to handle
	set PC, gc_move_to_grey
:gc_object_list_mark_finished_next_ptr
	set b, [gc_marking_b]
	set j, gc_object_list_mark_finished
	set a,  (0x0001 + b) ;move to value_ptr
	ife [a], 0 ;was a null value_ptr we're done here
		set PC, gc_object_list_mark_finished
	set a, [a]
	set PC, gc_move_to_grey
:gc_object_list_mark_finished
	set PC, [gc_marking_j]

:gc_object_array_mark
	set x, (0x0001 + b)
	add x, 2 ;add 2 so that we can start i past the tag and length
	set [gc_marking_x], x ;x is the array length
	set [gc_marking_b], b ;b is the object
	set [gc_marking_j], j
	set i, 2 ;start past the tag and length
	set [gc_marking_i], i ;i is the index into the array that we're going to mark
	set j, gc_object_array_mark_loop
:gc_object_array_mark_loop
	ife [gc_marking_i], [gc_marking_x] ;we're at the end
		set PC, [gc_marking_j]
	set b, [gc_marking_b]
	add b, i ;move to the array element we want
	add [gc_marking_i], 1 ;increment to make the if conditions simpler below
	set a, [b] ;deref to the object handle for our target array element
	ife a, 0 ;did we have a null handle?
		set PC, gc_object_array_mark_loop ;just skip the mark to the next one
	set a, [a]
	set PC, gc_move_to_grey

:gc_environment_mark
	set [gc_marking_b], b	
	set [gc_marking_j], j
	set a, b
	set a, (0x0001 + a) ;deref to the parent object handle
	set j, gc_environment_mark_function
	ife a, 0 ;was a null parent skip it and do the value
		set PC, j
	set PC, gc_move_to_grey
:gc_environment_mark_function
	set a, [gc_marking_b]
	set a, (0x0003 + a) ;deref to function object handle
	set j, gc_environment_mark_dynamic
	ife a, 0 ;was a null function skip it and do the value
		set PC, j
	set PC, gc_move_to_grey
:gc_environment_mark_dynamic
	set a, [gc_marking_b]
	set a, (0x0004 + a) ;deref to dynamic_lookup_tree object handle
	set j, gc_environment_mark_objects_loop
	ife a, 0 ;was a null dynamic_lookup_tree skip it and do the value
		set PC, j
	set PC, gc_move_to_grey
:gc_environment_mark_objects_loop
	set a, [gc_marking_b]
	set [gc_marking_z], (0x0005 + a) ;params count
	add [gc_marking_z], (0x0006 + a) ;locals count
	add a, 0x0007 ;skip ahead to the start of the objects
	add [gc_marking_z], a ;set gc_marking_z to the end ptr for comparisons
	set [gc_marking_i], a
	set j, gc_environment_mark_objects_loop_body 
:gc_environment_mark_objects_loop_body
	ife [gc_marking_i], [gc_marking_z] ;we're done
		set PC, gc_environment_mark_objects_loop_finished ;return out of the marker
	set a, [gc_marking_i]
	set a, [a] ;deref to object handle from our array index
	add [gc_marking_i], 1 ;advance i ahead of the grey move to simplify the loop
	ife a, 0 ;we had a null, dont try to move it to grey
		set PC, j
	set PC, gc_move_to_grey
:gc_environment_mark_objects_loop_finished
	set j, [gc_marking_j]
	set PC, j

;**************************************************************************************************
;***************** gc object promotion routines *************************************************
;**************************************************************************************************

;the dispatched routines just need to return the size in b
;without touching a
;j <- gc_promote_object(handle a)
:gc_promote_object
	set [gc_promote_j], j
	set j, gc_promote_finish_size
	set b, [gc_size_dispatch]
	set c, [a]
	set c, [c] ;deref the handle
	shl c, 8 ;shift away the upper 8bits
	shr c, 8 ;and back again so we have a good number
	add b, c ;add our object type tag to the mark dispatcher
	set PC, b ;do the dispatch
:gc_promote_finish_size
	set c, b
	set a, [a] ;deref to the object
	set b, [gc_gen2_pos]
	set x, b
	add x, c
	ifg x, [gc_perm_gen_pos] ;not enough room
		set PC, gc_mid_gen1_collection_overflow
	set j, [gc_promote_j]
	set PC, gc_mem_cpy


	
;**************************************************************************************************
;***************** gc gen1 collection routines ************************************************
;**************************************************************************************************

;start with the current environment, mark it grey
;mark the head of the grey list black until 
;the grey list is null
;everything left in allocated is garbage
;mark all black list objects to be white
;mark all black list objects to have an incremented gc count
;if the object has survived more then 4 collections
;move it to gen2
;add allocated list to the free list
;set allocated list to the black list
;black list is kept sorted when its created
;realloc gen1 surviving objects 
:gc_collect_gen1
	set a, [gc_current_environment]
	set [gc_collect_j], j
	set j, gc_collect_gen1_grey_loop
	ife a, 0 ;there were no active environments so just collect everything
		set PC, gc_collect_gen1_grey_loop_finished
	set PC, gc_move_to_grey
:gc_collect_gen1_grey_loop
	set a, [gc_gen1_grey_list]
	ife a, 0 ;null grey list, we're done here
		set PC, gc_collect_gen1_grey_loop_finished
	set [gc_gen1_grey_list], (0x0001 + a) ;pop one off the stack
	set PC, gc_blacken_object
:gc_collect_gen1_grey_loop_finished
	set j, [gc_collect_j]
	set [gc_collect_a], [gc_gen1_black_list]
	set [gc_gen1_pos], 0xFE00  ;prep for reallocation by reseting the allocation location
:gc_collect_gen1_white_black_loop
	set a, [gc_collect_a] ;get our current object handle
	ife a, 0 ;black loop is done
		set PC, gc_collect_gen1_white_black_loop_finished
	set b, a
	set b, (0x0001 + b) ;get the next object handle
	set x, [gc_collect_a] ;save off our prior object handle
	set [gc_collect_a], b ;replace our next loops target object handle with our current next handle
	set a, [a] ;deref the object handle
	xor [a], 0x0800 ;mark the object white
	set b, [a]
	shr b, 14 ;get the gc survival count
	ifg b, 4
		set PC, gc_collect_gen1_promote_black_head
	add b, 1 ;increment the survival count
	shl b, 14 ;shift it back into place
	bor [a], 0xC000 ;max the survival count
	xor [a], 0xC000 ;invert the survival count
	bor [a], b ;or in the survival count
	set a, x ;we want to send in our starting object handle to be compacted
	set j, gc_collect_gen1_white_black_loop
	set PC, gc_gen1_compact_object
:gc_collect_gen1_promote_black_head
	set a, x
	set j, gc_collect_gen1_white_black_loop
	set PC, gc_promote_object
:gc_collect_gen1_white_black_loop_finished
	set [gc_free_object_list_head], [gc_allocated_object_list_head]
	set [gc_allocated_object_list_head], [gc_gen1_black_list]
	set PC, [gc_collect_j]
	
; j <- gc_move_to_grey(handle a)
:gc_move_to_grey
	set y, [a] ;deref the object handle
	set y, [y] ;deref to the object tag
	shl y, 4
	shr y, 12
	ife y, 0x0002 ;is it grey already? skip out if it is
		set PC, j

	set y, (0x0001 + a) ;get the next_node

	ife [gc_allocated_object_list_head], a ;if we were the head then move to the next_node
		set [gc_allocated_object_list_head], y

	set b, gc_gen1_grey_list
	set PC, gc_move_list_node

;j <- gc_blacken_object(handle a)
:gc_blacken_object
	set b, [a]
	bor [b], 0x0800 ;or in black	
	set [gc_marking_a], a
	set [gc_marking_b], b
	set [gc_gen1_grey_list], (0x0001 + a) ;we're the head for the grey list so move it forward

	set b, gc_gen1_black_list
	set [gc_marking_j], j
	set j, gc_blackend_object_return_from_move
	set PC, gc_move_list_node_sorted_high
:gc_blackend_object_return_from_move
	set j, [gc_marking_j]
	set a, [gc_marking_a]
	set b, [gc_marking_b]
	set x, gc_mark_dispatch
	set y, [b] ;the tag
	shl y, 8 ;shift away the upper 8bits
	shr y, 8 ;and back again so we have a good number
	add x, y ;add our object type tag to the mark dispatcher
	set PC, [x]
	
;j <- gc_gen1_compact_object(handle a)
:gc_gen1_compact_object
	set [gc_promote_j], j
	set j, gc_gen1_compact_finish_size
	set b, gc_size_dispatch
	set c, [a]
	set c, [c] ;deref the handle
	shl c, 8 ;shift away the upper 8bits
	shr c, 8 ;and back again so we have a good number
	add b, c ;add our object type tag to the mark dispatcher
	set PC, [b] ;do the dispatch
:gc_gen1_compact_finish_size
	set c, b
	set a, [a] ;deref to the object
	set b, [gc_gen1_pos]
	set x, b
	add x, c
	ifg x, [gc_gen1_end] ;not enough room ? this shouldnt be possible
		set PC, gc_failure_to_big
	set [gc_gen1_pos], x ;advance the gen1
	set j, [gc_promote_j]
	set PC, gc_mem_cpy

;j <- gc_mem_cpy(dst a, src b, length c)
:gc_mem_cpy
	add c, a
:gc_mem_cpy_loop
	ife a, c
		set PC, j
	set [a], [b]
	add a, 1
	add b, 1
	set PC, gc_mem_cpy_loop
	
;trigger halt of current program and re-initialze gc structures
:gc_failure_to_big
	set a, 0x8000 ;we're going to clear the screen
	set b, 0x8180
:gc_mem_set
	ife a, b
		set PC, gc_failure_to_big_print
	set [a], 0
	add a, 1
	set PC, gc_mem_set

;print "out of memory"
;then wait several seconds before reseting
:gc_failure_to_big_print
	set [0x8000], 0x0a6f
	set [0x8001], 0x0a75
	set [0x8002], 0x0a74
	set [0x8003], 0x0a20
	set [0x8004], 0x0a6f
	set [0x8005], 0x0a66
	set [0x8006], 0x0a20
	set [0x8007], 0x0a6d
	set [0x8008], 0x0a65
	set [0x8009], 0x0a6d
	set [0x800a], 0x0a6f
	set [0x800b], 0x0a72
	set [0x800c], 0x0a79
	set a, 1000
:gc_failure_wait
	ife a, 0
		set PC, gc_init
	sub a, 1
	set PC, gc_failure_wait
	
;j <- gc_get_handle(object a, out next-handle b)
:gc_get_handle
	ifn [gc_free_object_list_head], 0x0000
		set PC, gc_get_free_handle
	
	set b, [gc_allocated_object_list_head] ;set the next node as the current head of allocated list
	set PC, gc_new_list_node
:gc_get_free_handle
	set b, [gc_free_object_list_head]
	set [gc_free_object_list_head], (0x0001 + b) ;remove ourselves from the free list
	ife (0x0001 + b), 0
		set PC, gc_get_free_handle_done	
	set (0x0002 + b), 0x0000 ;remove ourselves as the new head's prior node
:gc_get_free_handle_done
	set [b], a ;actually store the object in the node
:gc_get_handle_finish
	set [gc_allocated_object_list_head], b ;set ourselves as the new head of allocated list
	set PC, j
	
; this is a double linked list ment to be used as an object handle only
;j <- gc_new_list_node(value a, ref next_ptr b, prior_ptr c)
:gc_new_list_node
	set x, [gc_perm_gen_pos]
	add [gc_perm_gen_pos], 3
	ifn b, 0 ;if there was a next_ptr
		set (0x0002 + b), [gc_perm_gen_pos] ;set the next_ptr->prior_ptr to the node we are about to make
	ifg [gc_perm_gen_pos], [gc_perm_gen_end]
		set PC, gc_failure_to_big ;ran out of memory in the perm gen
	set (0x0002 + x), c ;set the prior pointer
	set (0x0001 + x), b ;set the next pointer
	set [x], a ;set the object pointer
	set b, x ;b is the return result so that we can quickly reverse allocate a linked list
	set pc, gc_get_handle_finish
	
;j <- gc_move_list_node(current-node a, new-head* b, )
:gc_move_list_node
	;did we have a null prior node, then skip this
	ife (0x0002 + a), 0 ;is prior node null?
		set PC, gc_move_list_node_after_set_prior

	set z, (0x0002 + a) ;set z to a->prior_node
	set (0x0001 + z), (0x0001 + a) ;a ->prior-node->next-node = a->next-node
:gc_move_list_node_after_set_prior
	ife (0x0001 + a), 0 ;did we have a null next node, then skip this
		set PC, gc_move_list_node_after_set_next
	set z, (0x0001 + a) ;set z to a->next_node
	set (0x0002 + z), (0x0002 + a) ;a->next-node->prior-node = a->prior-node

	set (0x0001 + a), [b] ;set our next_ptr to the new-head
	set (0x0002 + a), 0x0000 ;clear our prior_ptr
:gc_move_list_node_after_set_next
	set [b], a ;place ourselves as the destination list head
	set PC, j	

;j <- gc_move_list_node_sorted_high(current-node a, new-head* b)
:gc_move_list_node_sorted_high

	set x, [b]
	ife x, 0 ;did we have any empty list?
		set PC, gc_move_list_node
	ifg [a], [x] ;we're sorted
		set PC, gc_move_list_node
	set c, [x]
	set c, (0x0001 + c) ;get new-head->next_node
	ife c, 0 ;null next_node
		set PC, gc_move_list_node_sorted_high_end
	set b, x ;move b to the pointer to new-head->next_node
	add b, 1
	set PC, gc_move_list_node_sorted_high
:gc_move_list_node_sorted_high_end
	;old_head_prior = [new-head]->prior_node
	;if(old_head_prior != NULL)
	;	old_head_prior->next_node = current-node
	set y, [b]
	set y, (0x0002 + y) ;y = [new-head]->prior_node
	
	ife y, 0 ;i dont think this should ever occur
		set PC, gc_move_list_node
	set (0x0001 + y), a
	set c, a
	set a, [b]
	set b, c
	add b, 2 ;advance to the address of current-node->prior_node
	set PC, gc_move_list_node
	
;	0x14 - environment
;		parent
;		resume-ip (this is an absolute ip if there isnt a function in the environment
;			if there is a function this is an offset to execution
;			it needs to be an offset so that functions participate in gc compaction
;		function (this is null if we arent really a function environment)
;		dynamic_lookup_tree (dynamic symbols are assigned id's globaly, and are looked up in the nearest environment)
;		param-count
;		local-object-count
;		params (objects)
;		local-objects
;sets the current environment to be this new environment
;sets resume-ip to j (since that should be the start of this new environment)
;if we're dispatching to a loaded function, we should set the function slot
;if we dont, the function might get garbage collected and disappear out from under us
;j + [function ip] <- gc_new_environment(param-count a, local-object-count b, function c)
;our newly created environment is [gc_current_environment]
:gc_new_environment
	set z, 7
	add z, a
	add z, b
	set [gc_transfer_j], gc_new_environment_post_check
	set PC, gc_check_collection ;check if we have enough memory to do this allocation
:gc_new_environment_post_check
	set y, [gc_gen1_pos]
	set (0x0006 + y), b
	set (0x0005 + y), a
	set (0x0004 + y), 0x0000 ; we dont have any dynamic objects yet, set these externally
	set (0x0003 + y), c ;set the function
	set (0x0002 + y), j ;set the resume-ip
	set (0x0001 + y), [gc_current_environment] ;set the parent
	set [y], 0x0014 ;set the tag
	add [gc_gen1_pos], 7
	add [gc_gen1_pos], a
	add [gc_gen1_pos], b
	set a, y
	set b, [gc_current_environment]
	set [gc_transfer_j], j
	set j, gc_new_environment_after_get_handle
	set PC, gc_get_handle
:gc_new_environment_after_get_handle
	set [gc_current_environment], b ;set the current_environment to our new environment handle
	set j, [gc_transfer_j]
	ife (0x0003 + a), 0 ;did we have a function
		set PC, gc_new_environment_function_dispatch
	set PC, j
:gc_new_environment_function_dispatch
	set x, [c]
	add j, (0x0003 + x) ;skip to instructions
	set PC, j
	
;dont touch any argument register we arent going to restore
;[gc_transfer_j] <- gc_check_collection(requested-size z)
:gc_check_collection
	set x, [gc_gen1_pos]
	add x, z
	ifn o, 0 ;check if there is any overflow
		set PC, gc_check_collection_trigger_thunk
	set PC, [gc_transfer_j] ;we had enought memory transfer back
:gc_check_collection_trigger_thunk
	set [gc_transfer_a], a
	set [gc_transfer_b], b
	set [gc_transfer_c], c
	set [gc_transfer_i], [gc_transfer_j] ;we need an extra return point to make this generic
	set [gc_transfer_j], j	
	set j, gc_check_collection_return_thunk
	set PC, gc_collect_gen1 ;do the collection
:gc_check_collection_return_thunk
	set a, [gc_transfer_a]
	set b, [gc_transfer_b]
	set c, [gc_transfer_c]
	set j, [gc_transfer_j]
	set PC, [gc_transfer_i] ;jump back to our extra return point (the originating allocator)

:test_gc_new_enviornment
	add sp, 1
	set a, sp
	div a, 4
	ife o, 0
		set [gc_current_environment], 0x0000
	set a, 8
	set b, 4
	set c, 0x0000
	set j, test_gc_new_enviornment
	set PC, gc_new_environment


:static_code_end
	dat 0x0000
