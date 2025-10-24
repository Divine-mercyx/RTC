module rtc::call_session {
    use std::string;
    use sui::event;

    // ============ EVENTS ============
    public struct CallInitiated has copy, drop {
        session_id: ID,
        caller: address,
        callee: address,
        caller_profile: ID,
        callee_profile: ID,
        timestamp: u64,
    }

    public struct CallSessionCreated has copy, drop {
        session_id: ID,
        caller: address,
        callee: address,
        timestamp: u64,
    }

    public struct CallAnswered has copy, drop {
        session_id: ID,
        callee: address,
        timestamp: u64,
    }

    public struct CallEnded has copy, drop {
        session_id: ID,
        ended_by: address,
        timestamp: u64,
        duration_seconds: u64,
    }

    public struct OfferUpdated has copy, drop {
        session_id: ID,
        updated_by: address,
    }

    public struct AnswerUpdated has copy, drop {
        session_id: ID,
        updated_by: address,
    }

    // ============ STRUCTS ============
    public struct CallSession has key, store {
        id: UID,
        caller: address,
        callee: address,
        caller_profile: ID,  // Reference to caller's Profile
        callee_profile: ID,  // Reference to callee's Profile
        
        // WebRTC Signaling Data
        offer_sdp: string::String,    // Caller's SDP offer
        answer_sdp: string::String,   // Callee's SDP answer
        
        // Call Metadata
        status: u8,           // 0=initiated, 1=active, 2=ended, 3=declined
        initiated_at: u64,    // Block timestamp when call started
        answered_at: u64,     // Block timestamp when call answered
        ended_at: u64,        // Block timestamp when call ended
        
        // ICE Candidates (simplified - could be a table for multiple)
        caller_ice_candidate: string::String,
        callee_ice_candidate: string::String,
    }

    // ============ CONSTANTS ============
    const STATUS_INITIATED: u8 = 0;
    const STATUS_ACTIVE: u8 = 1;
    const STATUS_ENDED: u8 = 2;
    const STATUS_DECLINED: u8 = 3;

    const E_NOT_CALLER: u64 = 0;
    const E_NOT_CALLEE: u64 = 1;
    const E_INVALID_STATUS: u64 = 2;
    const E_CALL_ALREADY_ENDED: u64 = 3;

    // ============ PUBLIC FUNCTIONS ============

    /// Create a new call session (initiate a call)
    public fun create_call_session(
        caller: address,
        callee: address,
        caller_profile_id: ID,
        callee_profile_id: ID,
        offer_sdp: vector<u8>,
        ctx: &mut TxContext
    ): CallSession {
        let timestamp = tx_context::epoch(ctx);
        
        let session = CallSession {
            id: object::new(ctx),
            caller,
            callee,
            caller_profile: caller_profile_id,
            callee_profile: callee_profile_id,
            offer_sdp: string::utf8(offer_sdp),
            answer_sdp: string::utf8(b""),
            status: STATUS_INITIATED,
            initiated_at: timestamp,
            answered_at: 0,
            ended_at: 0,
            caller_ice_candidate: string::utf8(b""),
            callee_ice_candidate: string::utf8(b""),
        };

        // Emit event
        event::emit(CallInitiated {
            session_id: object::id(&session),
            caller,
            callee,
            caller_profile: caller_profile_id,
            callee_profile: callee_profile_id,
            timestamp,
        });

        session
    }

    /// Answer a call - provide SDP answer
    public fun answer_call(
        session: &mut CallSession,
        answer_sdp: vector<u8>,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == session.callee, E_NOT_CALLEE);
        assert!(session.status == STATUS_INITIATED, E_INVALID_STATUS);
        
        session.answer_sdp = string::utf8(answer_sdp);
        session.status = STATUS_ACTIVE;
        session.answered_at = tx_context::epoch(ctx);

        event::emit(CallAnswered {
            session_id: object::id(session),
            callee: sender,
            timestamp: session.answered_at,
        });
    }

    /// End a call
    public fun end_call(
        session: &mut CallSession,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == session.caller || sender == session.callee, E_NOT_CALLER);
        assert!(session.status != STATUS_ENDED, E_CALL_ALREADY_ENDED);
        
        let current_time = tx_context::epoch(ctx);
        session.status = STATUS_ENDED;
        session.ended_at = current_time;

        let duration = if (session.answered_at > 0) {
            current_time - session.answered_at
        } else {
            0
        };

        event::emit(CallEnded {
            session_id: object::id(session),
            ended_by: sender,
            timestamp: current_time,
            duration_seconds: duration,
        });
    }

    /// Decline a call
    public fun decline_call(
        session: &mut CallSession,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == session.callee, E_NOT_CALLEE);
        assert!(session.status == STATUS_INITIATED, E_INVALID_STATUS);
        
        session.status = STATUS_DECLINED;
        session.ended_at = tx_context::epoch(ctx);

        event::emit(CallEnded {
            session_id: object::id(session),
            ended_by: sender,
            timestamp: session.ended_at,
            duration_seconds: 0,
        });
    }

    /// Update ICE candidate (for NAT traversal)
    public fun update_caller_ice_candidate(
        session: &mut CallSession,
        ice_candidate: vector<u8>,
        ctx: &TxContext
    ) {
        assert!(tx_context::sender(ctx) == session.caller, E_NOT_CALLER);
        session.caller_ice_candidate = string::utf8(ice_candidate);
        
        event::emit(OfferUpdated {
            session_id: object::id(session),
            updated_by: session.caller,
        });
    }

    public fun update_callee_ice_candidate(
        session: &mut CallSession,
        ice_candidate: vector<u8>,
        ctx: &TxContext
    ) {
        assert!(tx_context::sender(ctx) == session.callee, E_NOT_CALLEE);
        session.callee_ice_candidate = string::utf8(ice_candidate);
        
        event::emit(AnswerUpdated {
            session_id: object::id(session),
            updated_by: session.callee,
        });
    }

    // ============ ENTRY FUNCTIONS ============

    /// Entry point to initiate a call - UPDATED to accept IDs instead of profile references
    entry fun initiate_call_entry(
        caller_profile_id: ID,
        callee: address,
        callee_profile_id: ID,
        offer_sdp: vector<u8>,
        ctx: &mut TxContext
    ) {
        let caller = tx_context::sender(ctx);
        
        let session = create_call_session(
            caller,
            callee,
            caller_profile_id,
            callee_profile_id,
            offer_sdp,
            ctx
        );
        
        let session_id = object::id(&session);
        
        // Transfer to CALLER (transaction sender) so it appears in transaction results
        transfer::transfer(session, caller);
        
        // Emit additional event with session details for frontend
        event::emit(CallSessionCreated {
            session_id: session_id,
            caller: caller,
            callee: callee,
            timestamp: tx_context::epoch(ctx),
        });
    }

    /// Entry point to answer a call
    entry fun answer_call_entry(
        session: &mut CallSession,
        answer_sdp: vector<u8>,
        ctx: &TxContext
    ) {
        answer_call(session, answer_sdp, ctx);
    }

    /// Entry point to end a call
    entry fun end_call_entry(
        session: &mut CallSession,
        ctx: &TxContext
    ) {
        end_call(session, ctx);
    }

    /// Entry point to decline a call
    entry fun decline_call_entry(
        session: &mut CallSession,
        ctx: &TxContext
    ) {
        decline_call(session, ctx);
    }

    /// Entry point to update caller ICE candidate
    entry fun update_caller_ice_candidate_entry(
        session: &mut CallSession,
        ice_candidate: vector<u8>,
        ctx: &TxContext
    ) {
        update_caller_ice_candidate(session, ice_candidate, ctx);
    }

    /// Entry point to update callee ICE candidate
    entry fun update_callee_ice_candidate_entry(
        session: &mut CallSession,
        ice_candidate: vector<u8>,
        ctx: &TxContext
    ) {
        update_callee_ice_candidate(session, ice_candidate, ctx);
    }

    // ============ GETTER FUNCTIONS ============

    /// Get call status
    public fun get_status(session: &CallSession): u8 {
        session.status
    }

    /// Get caller address
    public fun get_caller(session: &CallSession): address {
        session.caller
    }

    /// Get callee address
    public fun get_callee(session: &CallSession): address {
        session.callee
    }

    /// Get SDP offer
    public fun get_offer_sdp(session: &CallSession): &string::String {
        &session.offer_sdp
    }

    /// Get SDP answer
    public fun get_answer_sdp(session: &CallSession): &string::String {
        &session.answer_sdp
    }

    /// Get call duration (if ended)
    public fun get_duration(session: &CallSession): u64 {
        if (session.status == STATUS_ENDED && session.answered_at > 0) {
            session.ended_at - session.answered_at
        } else {
            0
        }
    }

    /// Get ICE candidates
    public fun get_caller_ice_candidate(session: &CallSession): &string::String {
        &session.caller_ice_candidate
    }

    public fun get_callee_ice_candidate(session: &CallSession): &string::String {
        &session.callee_ice_candidate
    }

    /// Check if call is active
    public fun is_active(session: &CallSession): bool {
        session.status == STATUS_ACTIVE
    }

    /// Check if call can be answered
    public fun can_answer(session: &CallSession): bool {
        session.status == STATUS_INITIATED
    }
}