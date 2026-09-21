-- 1. LOGIN (Get user credential)
SELECT 
    id, 
    full_name, 
    email, 
    password, 
    role, 
    location,
    bio,
    avatar_url
FROM users 
WHERE email = 'Argo@example.com';

-- 2. REGISTER (Set user credential with condition)
INSERT INTO users (full_name, email, password, location, bio, avatar_url, role)
VALUES (
    'Argo Nugroho', 
    'Argo@example.com', 
    'Argo123', 
    'Jakarta', 
    'Product Manager antusias', 
    NULL, 
    'attendee'
)

-- 3. GET EVENT LIST WITH SEARCH & FILTER
SELECT 
    e.id,
    e.title,
    e.slug,
    e.overview,
    e.start_time,
    e.end_time,
    e.location_type,
    e.city,
    e.address,
    e.capacity,
    e.thumbnail_url,
    e.status,
    c.name AS community_name,
    u.full_name AS organizer_name,
    COUNT(er.id) FILTER (WHERE er.status = 'registered') AS total_registered,
    (COUNT(er.id) FILTER (WHERE er.status = 'registered') >= e.capacity) AS is_full
FROM events e
LEFT JOIN communities c ON e.community_id = c.id
JOIN users u ON e.organizer_id = u.id
LEFT JOIN event_categories ec ON e.id = ec.event_id
LEFT JOIN categories cat ON ec.category_id = cat.id
LEFT JOIN event_registrations er ON e.id = er.event_id
WHERE e.status = 'published'
  AND (e.title ILIKE '%Go%' OR e.city ILIKE '%Go%') 
GROUP BY e.id, c.name, u.full_name
ORDER BY e.start_time ASC
LIMIT 10 OFFSET 0;


-- 4. GET EVENT DETAIL
SELECT 
    e.id,
    e.title,
    e.slug,
    e.overview,
    e.description,
    e.start_time,
    e.end_time,
    e.location_type,
    e.city,
    e.address,
    e.capacity,
    e.thumbnail_url,
    e.status,
    e.created_at,
    -- Info Komunitas
    c.id AS community_id,
    c.name AS community_name,
    c.cover_image_url AS community_cover,
    -- Info Organizer
    u.id AS organizer_id,
    u.full_name AS organizer_name,
    u.avatar_url AS organizer_avatar,
    -- Kapasitas Tiket
    COUNT(er.id) FILTER (WHERE er.status = 'registered') AS registered_count,
    (e.capacity - COUNT(er.id) FILTER (WHERE er.status = 'registered')) AS remaining_capacity,
    (COUNT(er.id) FILTER (WHERE er.status = 'registered') >= e.capacity) AS is_full,
    COALESCE(ARRAY_AGG(DISTINCT cat.name) FILTER (WHERE cat.name IS NOT NULL), '{}') AS categories
FROM events e
LEFT JOIN communities c ON e.community_id = c.id
JOIN users u ON e.organizer_id = u.id
LEFT JOIN event_categories ec ON e.id = ec.event_id
LEFT JOIN categories cat ON ec.category_id = cat.id
LEFT JOIN event_registrations er ON e.id = er.event_id
WHERE e.id = 1
GROUP BY e.id, c.id, u.id;


-- 5. JOIN / LEAVE EVENT    
-- A. Join Event 
INSERT INTO event_registrations (event_id, user_id, status, registered_at, updated_at)
VALUES (2, 1, 'registered', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (event_id, user_id) 
DO UPDATE SET status = 'registered', updated_at = CURRENT_TIMESTAMP
RETURNING id, event_id, user_id, status;


-- B. Leave Event 
UPDATE event_registrations
SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
WHERE event_id = 2 AND user_id = 1
RETURNING id, event_id, user_id, status, updated_at;


-- 6. GET UPCOMING EVENT
SELECT 
    e.id,
    e.title,
    e.slug,
    e.overview,
    e.start_time,
    e.end_time,
    e.location_type,
    e.city,
    e.capacity,
    e.thumbnail_url,
    c.name AS community_name,
    COUNT(er.id) FILTER (WHERE er.status = 'registered') AS registered_count
FROM events e
LEFT JOIN communities c ON e.community_id = c.id
LEFT JOIN event_registrations er ON e.id = er.event_id
WHERE e.status = 'published' 
  AND e.start_time > CURRENT_TIMESTAMP
GROUP BY e.id, c.name
ORDER BY e.start_time ASC
LIMIT 6;


-- 7. GET MY EVENT 
-- A. My Upcoming Events 
SELECT 
    e.id,
    e.title,
    e.slug,
    e.start_time,
    e.end_time,
    e.location_type,
    e.city,
    e.address,
    e.thumbnail_url,
    er.status AS registration_status,
    c.name AS community_name
FROM event_registrations er
JOIN events e ON er.event_id = e.id
LEFT JOIN communities c ON e.community_id = c.id
WHERE er.user_id = 1
  AND er.status = 'registered'
  AND e.start_time >= CURRENT_TIMESTAMP
ORDER BY e.start_time ASC;

-- B. My Past Events 
SELECT 
    e.id,
    e.title,
    e.slug,
    e.start_time,
    e.end_time,
    e.location_type,
    e.city,
    e.thumbnail_url,
    er.status AS registration_status,
    c.name AS community_name
FROM event_registrations er
JOIN events e ON er.event_id = e.id
LEFT JOIN communities c ON e.community_id = c.id
WHERE er.user_id = 1
  AND er.status IN ('registered', 'attended')
  AND e.end_time < CURRENT_TIMESTAMP
ORDER BY e.start_time DESC;

-- C. My Saved Events 
SELECT 
    e.id,
    e.title,
    e.slug,
    e.start_time,
    e.end_time,
    e.location_type,
    e.city,
    e.thumbnail_url,
    c.name AS community_name,
    COUNT(er.id) FILTER (WHERE er.status = 'registered') AS registered_count,
    eb.created_at AS bookmarked_at
FROM event_bookmarks eb
JOIN events e ON eb.event_id = e.id
LEFT JOIN communities c ON e.community_id = c.id
LEFT JOIN event_registrations er ON e.id = er.event_id
WHERE eb.user_id = 1
GROUP BY e.id, c.name, eb.created_at
ORDER BY eb.created_at DESC;


-- 8. SAVE / BOOKMARK EVENT // jaga-jaga
-- A. Bookmark Event (User 1 bookmark Event 2)
-- INSERT INTO event_bookmarks (user_id, event_id)
-- VALUES (1, 2)
-- ON CONFLICT (user_id, event_id) DO NOTHING;

-- -- B. Unbookmark Event
-- DELETE FROM event_bookmarks
-- WHERE user_id = 1 AND event_id = 2;
    

-- 9. GET COMMUNITY LIST WITH SEARCH & FILTER
SELECT 
    c.id,
    c.name,
    c.slug,
    c.description,
    c.cover_image_url,
    COUNT(DISTINCT cm.id) AS members_count,
    COUNT(DISTINCT e.id) FILTER (WHERE e.start_time > CURRENT_TIMESTAMP AND e.status = 'published') AS upcoming_events_count,
    EXISTS(SELECT 1 FROM community_members WHERE community_id = c.id AND user_id = 1) AS is_joined,
    COALESCE(ARRAY_AGG(DISTINCT cat.name) FILTER (WHERE cat.name IS NOT NULL), '{}') AS categories
FROM communities c
LEFT JOIN community_members cm ON c.id = cm.community_id
LEFT JOIN events e ON c.id = e.community_id
LEFT JOIN community_categories cc ON c.id = cc.community_id
LEFT JOIN categories cat ON cc.category_id = cat.id
WHERE c.is_active = TRUE
GROUP BY c.id
ORDER BY members_count DESC;


-- 10. GET COMMUNITY DETAIL 
SELECT 
    c.id,
    c.name,
    c.slug,
    c.description,
    c.cover_image_url,
    c.created_at,
    u.id AS organizer_id,
    u.full_name AS organizer_name,
    u.avatar_url AS organizer_avatar,
    COUNT(DISTINCT cm.id) AS members_count,
    COUNT(DISTINCT e.id) FILTER (WHERE e.start_time > CURRENT_TIMESTAMP AND e.status = 'published') AS upcoming_events_count,
    EXISTS(SELECT 1 FROM community_members WHERE community_id = c.id AND user_id = 1) AS is_joined
FROM communities c
JOIN users u ON c.organizer_id = u.id
LEFT JOIN community_members cm ON c.id = cm.community_id
LEFT JOIN events e ON c.id = e.community_id
WHERE c.id = 1 AND c.is_active = TRUE
GROUP BY c.id, u.id;


-- 11. GET POPULAR COMMUNITIES (Score Bobot: Member * 1 + Event * 5 + Attendee * 2)
SELECT 
    c.id,
    c.name,
    c.slug,
    c.description,
    c.cover_image_url,
    COUNT(DISTINCT cm.id) AS total_members,
    COUNT(DISTINCT e.id) FILTER (WHERE e.start_time > CURRENT_TIMESTAMP AND e.status = 'published') AS total_upcoming_events,
    (COUNT(DISTINCT cm.id) * 1) + 
    (COUNT(DISTINCT e.id) FILTER (WHERE e.start_time > CURRENT_TIMESTAMP AND e.status = 'published') * 5) + 
    (COALESCE(SUM(CASE WHEN er.status = 'registered' THEN 1 ELSE 0 END), 0) * 2) AS popularity_score
FROM communities c
LEFT JOIN community_members cm ON c.id = cm.community_id
LEFT JOIN events e ON c.id = e.community_id
LEFT JOIN event_registrations er ON e.id = er.event_id
WHERE c.is_active = TRUE
GROUP BY c.id
ORDER BY popularity_score DESC, total_members DESC
LIMIT 5;


-- 12. JOIN / LEAVE COMMUNITY 
-- A. Join Komunitas
INSERT INTO community_members (community_id, user_id, community_role, joined_at)
VALUES (2, 1, 'member', CURRENT_TIMESTAMP)
ON CONFLICT (community_id, user_id) DO NOTHING;

-- B. Leave Komunitas
DELETE FROM community_members
WHERE community_id = 2 AND user_id = 1;


-- 13. GET COMMUNITY MEMBER 
SELECT 
    u.id,
    u.full_name,
    u.avatar_url,
    u.location,
    cm.community_role,
    cm.joined_at
FROM community_members cm
JOIN users u ON cm.user_id = u.id
WHERE cm.community_id = 1
ORDER BY cm.joined_at ASC;


-- 14. GET USER PROFILE 
SELECT 
    u.id,
    u.full_name,
    u.email,
    u.location,
    u.avatar_url,
    u.bio,
    u.role,
    u.created_at AS joined_date
FROM users u
WHERE u.id = 5;

-- contoh ke 2 select yang memunculkan juga event, communites,sa ve
-- SELECT 
--     u.id,
--     u.full_name,
--     u.email,
--     u.location,
--     u.avatar_url,
--     u.bio,
--     u.role,
--     u.created_at AS joined_date,
--     (SELECT COUNT(*) FROM community_members cm WHERE cm.user_id = u.id) AS total_joined_communities,
--     (SELECT COUNT(*) FROM event_registrations er WHERE er.user_id = u.id AND er.status = 'registered') AS total_registered_events,
--     (SELECT COUNT(*) FROM event_bookmarks eb WHERE eb.user_id = u.id) AS total_saved_events,
--     (SELECT COUNT(*) FROM events e WHERE e.organizer_id = u.id) AS total_organized_events
-- FROM users u
-- WHERE u.id = 1;


-- 15. CHANGE USER PROFILE 
UPDATE users
SET 
    full_name = 'Sugeng',
    location = 'Bandung, Jawa Barat',
    bio = 'Senior Frontend Engineer & Community Speaker',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 5
RETURNING id, full_name, email, location, bio, avatar_url, updated_at;


-- 16. CHANGE PASSWORD 
UPDATE users
SET 
    password = 'habibganteng',
    updated_at = CURRENT_TIMESTAMP
WHERE id = 5
RETURNING id, email, updated_at;


-- 17. GET / SET TESTIMONY
-- A. Get Testimonials 
SELECT 
    t.id,
    t.content,
    t.author_title,
    t.created_at,
    u.full_name,
    u.avatar_url
FROM testimonials t
JOIN users u ON t.user_id = u.id
WHERE t.is_featured = TRUE
ORDER BY t.created_at DESC
LIMIT 6;


-- Buat menampilkan testimonial semuanya
-- SELECT 
--     t.id,
--     t.content,
--     t.author_title,
--     t.is_featured,
--     t.created_at,
--     u.full_name,
--     u.avatar_url
-- FROM testimonials t
-- JOIN users u ON t.user_id = u.id
-- ORDER BY t.created_at DESC
-- LIMIT 6;

-- B. Set Testimony baru
INSERT INTO testimonials (user_id, content, author_title, is_featured, created_at)
VALUES (
    5, 
    'EventHub completely changed how I network. The community pages make it so easy to find people who are into the same things. gg banget deh pokoknya anak putra solo', 
    'Frontend Engineer · Cakrawala Digital', 
    TRUE,
    CURRENT_TIMESTAMP
)
RETURNING id, content, author_title, created_at;


-- 18. GET MY NOTIFICATION 
SELECT 
    id,
    title,
    description,
    type,
    reference_type,
    reference_id,
    is_read,
    created_at
FROM notifications
WHERE user_id = 1
ORDER BY created_at DESC;


-- 19. GET ORGANIZER DASHBOARD AND INFORMATION 
-- A. Metrik Statistik Utama Organizer
SELECT 
    COUNT(e.id) AS total_events,
    COALESCE(SUM(reg.total_registered), 0) AS total_attendees,
    CASE 
        WHEN SUM(e.capacity) > 0 
        THEN ROUND((COALESCE(SUM(reg.total_registered), 0)::NUMERIC / SUM(e.capacity)::NUMERIC) * 100, 1)
        ELSE 0 
    END AS avg_fill_rate
FROM events e
LEFT JOIN (
    SELECT event_id, COUNT(*) AS total_registered 
    FROM event_registrations 
    WHERE status = 'registered' 
    GROUP BY event_id
) reg ON e.id = reg.event_id
WHERE e.organizer_id = 2;

-- B. Daftar Riwayat Event Milik Organizer
SELECT 
    e.id,
    e.title,
    e.slug,
    e.start_time,
    e.location_type,
    e.city,
    e.capacity,
    e.status,
    COUNT(er.id) FILTER (WHERE er.status = 'registered') AS total_registered
FROM events e
LEFT JOIN event_registrations er ON e.id = er.event_id
WHERE e.organizer_id = 2
GROUP BY e.id
ORDER BY e.created_at DESC;



-- 20. CREATE / EDIT EVENT
INSERT INTO events (
    organizer_id,
    community_id,
    title,
    slug,
    overview,
    description,
    start_time,
    end_time,
    location_type,
    city,
    address,
    capacity,
    thumbnail_url,
    status
) VALUES (
    2,
    1,
    'Go Advanced Microservices Workshop',
    'go-advanced-microservices-workshop',
    'Membangun microservices dengan gRPC dan Go.',
    'Workshop praktis arsitektur microservices tingkat lanjut.',
    TIMESTAMP WITH TIME ZONE '2026-11-15 09:00:00+07',
    TIMESTAMP WITH TIME ZONE '2026-11-15 17:00:00+07',
    'offline',
    'Bandung',
    'Bandung Tech Hub Lt. 2',
    80,
    'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4',
    'published'
)
RETURNING id, title, slug, status;

-- B. Edit Event 
UPDATE events
SET 
    title = 'Go Concurrency & Channels Masterclass',
    capacity = 120,
    updated_at = CURRENT_TIMESTAMP
WHERE id = 1 AND organizer_id = 2
RETURNING id, title, slug, capacity, updated_at;


-- 21. GET ADMIN DASHBOARD AND INFORMATION
SELECT 
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM events) AS total_events,
    (SELECT COUNT(*) FROM events WHERE status = 'published' AND start_time > CURRENT_TIMESTAMP) AS active_events,
    (SELECT COUNT(*) FROM communities WHERE is_active = TRUE) AS total_communities,
    (
        SELECT ROUND((COUNT(er.id) FILTER (WHERE er.status = 'registered')::NUMERIC / NULLIF(SUM(e.capacity), 0)::NUMERIC) * 100, 1)
        FROM events e
        LEFT JOIN event_registrations er ON e.id = er.event_id
    ) AS global_avg_fill_rate;
