select
    1 as document_id,
    'jira' as platform,
    '' as source_relation,
    current_timestamp() as most_recent_chunk_update,
    0 as chunk_index,
    50 as chunk_tokens_approximate,
    'Body' as chunk