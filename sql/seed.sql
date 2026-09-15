-- ========================================
-- SEED DATA
-- Run this after schema.sql
-- ========================================

-- Insert sample equipment
insert into equipment (equipment_id, name, category, status, description, location) values
('LAP-001', 'Dell Latitude 5520', 'Laptop', 'Available', '15.6" Business Laptop', 'Room 201'),
('LAP-002', 'HP ProBook 450', 'Laptop', 'Available', '15.6" Business Laptop', 'Room 201'),
('LAP-003', 'Lenovo ThinkPad X1', 'Laptop', 'Under Maintenance', '14" Premium Laptop', 'Room 202'),
('PRJ-001', 'Epson Projector', 'Projector', 'Available', 'Full HD Projector', 'Room 301'),
('PRJ-002', 'BenQ Projector', 'Projector', 'Available', 'Full HD Projector', 'Room 302'),
('SW-001', 'Cisco Switch 24P', 'Network', 'Available', '24-Port Gigabit Switch', 'Server Room'),
('SW-002', 'TP-Link Router', 'Network', 'Available', 'Wireless Router', 'Server Room'),
('PRT-001', 'HP LaserJet', 'Printer', 'Available', 'Monochrome Laser Printer', 'Room 201'),
('PRT-002', 'Canon Inkjet', 'Printer', 'Borrowed', 'Color Inkjet Printer', 'Room 203');
