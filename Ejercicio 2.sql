CREATE TABLE IF NOT EXISTS `customer_courier_conversations` (
  `id` int NOT NULL auto_increment primary key,
  `order_id` int DEFAULT NULL,
  `city_code` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `first_courier_message_time` datetime DEFAULT NULL,
  `first_customer_message_time` datetime DEFAULT NULL,
  `courier_message_count` bigint NOT NULL DEFAULT '0',
  `customer_message_count` bigint NOT NULL DEFAULT '0',
  `first_message_sender` varchar(8) NOT NULL DEFAULT '',
  `first_message_time` datetime DEFAULT NULL,
  `time_to_first_response` bigint DEFAULT NULL,
  `last_message_time` datetime DEFAULT NULL,
  `last_message_stage` varchar(16) CHARACTER SET utf8mb3 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `customer_courier_conversations`
(`order_id`,
`city_code`,
`first_courier_message_time`,
`first_customer_message_time`,
`courier_message_count`,
`customer_message_count`,
`first_message_sender`,
`first_message_time`,
`time_to_first_response`,
`last_message_time`,
`last_message_stage`)
SELECT 
    m.order_id,
    o.city_code,
    MIN(CASE WHEN m.sender_app_type LIKE 'Courier%' THEN m.message_sent_time ELSE NULL END) AS first_courier_message_time,
    MIN(CASE WHEN m.sender_app_type LIKE 'Customer%' THEN m.message_sent_time ELSE NULL END) AS first_customer_message_time,
    COUNT(CASE WHEN m.sender_app_type LIKE 'Courier%' THEN 1 ELSE NULL END) AS courier_message_count,
    COUNT(CASE WHEN m.sender_app_type LIKE 'Customer%' THEN 1 ELSE NULL END) AS customer_message_count,
    CASE 
        WHEN MIN(m.message_sent_time) = MIN(CASE WHEN m.sender_app_type LIKE 'Courier%' THEN m.message_sent_time ELSE NULL END) 
        THEN 'Courier' 
        ELSE 'Customer' 
    END AS first_message_sender,
    MIN(m.message_sent_time) AS first_message_time,
    TIMESTAMPDIFF(SECOND, 
                  MIN(m.message_sent_time), 
                  MIN(m2.message_sent_time)
    ) AS time_to_first_response,
    MAX(m.message_sent_time) AS last_message_time,
    MAX(m.order_stage) AS last_message_stage
FROM 
    customer_courier_chat_messages m
JOIN 
    orders o ON m.order_id = o.order_id
LEFT JOIN 
    customer_courier_chat_messages m2 ON m.order_id = m2.order_id 
    AND m2.message_sent_time > m.message_sent_time
GROUP BY 
    m.order_id, o.city_code;
