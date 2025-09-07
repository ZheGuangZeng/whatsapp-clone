#!/usr/bin/env python3

"""
Advanced Test Data Generation Script
This script generates realistic test data for the WhatsApp Clone project
with various scenarios and edge cases for comprehensive testing.
"""

import json
import random
import uuid
from datetime import datetime, timedelta
from typing import List, Dict, Any
import argparse

class TestDataGenerator:
    def __init__(self):
        self.users = []
        self.rooms = []
        self.messages = []
        self.meetings = []
        
        # Realistic names and data
        self.first_names = [
            'Alice', 'Bob', 'Carol', 'David', 'Emma', 'Frank', 'Grace', 'Henry',
            'Ivy', 'Jack', 'Karen', 'Louis', 'Maria', 'Nathan', 'Olivia', 'Peter',
            'Quinn', 'Rachel', 'Steve', 'Tina', 'Victor', 'Wendy', 'Xavier', 'Yvonne', 'Zack'
        ]
        
        self.last_names = [
            'Anderson', 'Brown', 'Davis', 'Evans', 'Foster', 'Garcia', 'Harris', 'Jackson',
            'Johnson', 'King', 'Lee', 'Miller', 'Nelson', 'Oliver', 'Parker', 'Quinn',
            'Roberts', 'Smith', 'Taylor', 'Underwood', 'Valdez', 'Wilson', 'Young', 'Zhang'
        ]
        
        self.status_messages = [
            'Available', 'Busy with work', 'In a meeting', 'On vacation 🏖️',
            'Coffee lover ☕', 'Gym time 💪', 'Reading 📚', 'Coding 💻',
            'Happy Friday! 🎉', 'Weekend vibes ✨', 'Love coffee', 'Always learning',
            'Working from home', 'Out for lunch', 'Be right back', 'Do not disturb'
        ]
        
        self.message_content_templates = [
            'Hey {name}! How are you doing?',
            'Good morning everyone!',
            'Has anyone seen the latest updates?',
            'Meeting at {time} today',
            'Great work on the project!',
            'Can we reschedule the call?',
            'Thanks for the help!',
            'Looking forward to our discussion',
            'Just finished the task',
            'Need some feedback on this',
            'Perfect! Let\'s proceed',
            'I agree with your suggestion',
            'Let me check and get back to you',
            'Sounds like a plan',
            'Awesome! 🎉',
            'That makes sense',
            'I have a question about...',
            'Could you clarify this?',
            'No worries, take your time',
            'Excellent point!'
        ]
        
        self.emojis = ['👍', '❤️', '😊', '🎉', '💪', '☕', '🚀', '✅', '🔥', '💯']
        
    def generate_users(self, count: int = 20) -> List[Dict[str, Any]]:
        """Generate realistic user data"""
        users = []
        
        for i in range(count):
            first_name = random.choice(self.first_names)
            last_name = random.choice(self.last_names)
            
            user = {
                'id': str(uuid.uuid4()),
                'display_name': f'{first_name} {last_name}',
                'email': f'{first_name.lower()}.{last_name.lower()}@example.com',
                'avatar_url': f'https://i.pravatar.cc/150?u={first_name.lower()}',
                'phone_number': f'+1{random.randint(2000000000, 9999999999)}',
                'status_message': random.choice(self.status_messages),
                'is_online': random.choice([True, False, False]),  # Bias towards offline
                'last_seen': self._random_past_time(hours=random.randint(0, 72)),
                'created_at': self._random_past_time(days=random.randint(1, 365))
            }
            
            users.append(user)
        
        self.users = users
        return users
    
    def generate_rooms(self, user_count: int = None) -> List[Dict[str, Any]]:
        """Generate rooms with realistic participant distributions"""
        if not self.users:
            raise ValueError("Generate users first")
            
        if user_count is None:
            user_count = len(self.users)
            
        rooms = []
        
        # Generate direct message rooms (50% of total rooms)
        direct_room_count = min(user_count // 2, 10)
        for i in range(direct_room_count):
            user1, user2 = random.sample(self.users[:user_count], 2)
            
            room = {
                'id': str(uuid.uuid4()),
                'name': None,  # Direct rooms don't have names
                'description': None,
                'type': 'direct',
                'created_by': user1['id'],
                'participants': [user1['id'], user2['id']],
                'avatar_url': None,
                'last_message_at': self._random_past_time(hours=random.randint(0, 48)),
                'created_at': self._random_past_time(days=random.randint(1, 30))
            }
            
            rooms.append(room)
        
        # Generate group rooms
        group_names = [
            'Development Team', 'Coffee Lovers ☕', 'Weekend Plans', 'Book Club 📚',
            'Fitness Squad 💪', 'Movie Night 🎬', 'Travel Enthusiasts ✈️', 
            'Tech Talk', 'Random Chat', 'Project Alpha', 'Daily Standup',
            'Lunch Group', 'Gaming Squad 🎮', 'Music Lovers 🎵'
        ]
        
        group_room_count = min(len(group_names), 8)
        for i in range(group_room_count):
            creator = random.choice(self.users[:user_count])
            participant_count = random.randint(3, min(8, user_count))
            participants = random.sample(self.users[:user_count], participant_count)
            
            room = {
                'id': str(uuid.uuid4()),
                'name': group_names[i],
                'description': f'{group_names[i]} group chat',
                'type': 'group',
                'created_by': creator['id'],
                'participants': [p['id'] for p in participants],
                'avatar_url': f'https://i.pravatar.cc/150?u={group_names[i].lower().replace(" ", "")}',
                'last_message_at': self._random_past_time(hours=random.randint(0, 24)),
                'created_at': self._random_past_time(days=random.randint(1, 90))
            }
            
            rooms.append(room)
        
        self.rooms = rooms
        return rooms
    
    def generate_messages(self, messages_per_room: int = 15) -> List[Dict[str, Any]]:
        """Generate realistic message conversations"""
        if not self.rooms:
            raise ValueError("Generate rooms first")
            
        messages = []
        
        for room in self.rooms:
            room_messages = []
            message_count = random.randint(5, messages_per_room)
            
            # Create a conversation flow
            conversation_start = self._random_past_time(hours=random.randint(1, 168))
            current_time = conversation_start
            
            for i in range(message_count):
                # Select random participant as sender
                sender_id = random.choice(room['participants'])
                
                # Generate content
                content = self._generate_message_content(room, sender_id)
                
                # Determine message type
                message_type = self._determine_message_type()
                
                # Reply to previous message sometimes
                reply_to = None
                if room_messages and random.random() < 0.3:  # 30% chance of reply
                    reply_to = random.choice(room_messages)['id']
                
                message = {
                    'id': str(uuid.uuid4()),
                    'room_id': room['id'],
                    'user_id': sender_id,
                    'content': content,
                    'type': message_type,
                    'reply_to': reply_to,
                    'created_at': current_time,
                    'reactions': self._generate_reactions(room['participants']),
                    'edited_at': None if random.random() > 0.1 else self._random_future_time(current_time, minutes=30),
                    'deleted_at': None if random.random() > 0.05 else self._random_future_time(current_time, hours=1)
                }
                
                room_messages.append(message)
                messages.append(message)
                
                # Increment time for next message (realistic conversation timing)
                current_time += timedelta(minutes=random.randint(1, 120))
        
        self.messages = messages
        return messages
    
    def generate_meetings(self, meeting_count: int = 8) -> List[Dict[str, Any]]:
        """Generate meeting data with various states"""
        if not self.rooms:
            raise ValueError("Generate rooms first")
            
        meetings = []
        
        meeting_titles = [
            'Daily Standup', 'Sprint Planning', 'Code Review', 'Team Retrospective',
            'Coffee Chat', 'Project Kickoff', 'Client Meeting', 'Design Review',
            'Architecture Discussion', 'Product Demo', 'Weekly Sync', 'All Hands'
        ]
        
        for i in range(min(meeting_count, len(meeting_titles))):
            # Select a room (prefer group rooms)
            group_rooms = [r for r in self.rooms if r['type'] == 'group']
            room = random.choice(group_rooms if group_rooms else self.rooms)
            
            host_id = random.choice(room['participants'])
            
            # Determine meeting state
            meeting_state = random.choices(
                ['upcoming', 'active', 'completed'],
                weights=[0.3, 0.2, 0.5]  # More completed meetings
            )[0]
            
            scheduled_time = self._generate_meeting_time(meeting_state)
            started_at = None
            ended_at = None
            
            if meeting_state == 'active':
                started_at = scheduled_time
            elif meeting_state == 'completed':
                started_at = scheduled_time
                ended_at = started_at + timedelta(minutes=random.randint(15, 120))
            
            meeting = {
                'id': str(uuid.uuid4()),
                'room_id': room['id'],
                'livekit_room_name': f'meeting_{str(uuid.uuid4()).replace("-", "")}',
                'host_id': host_id,
                'title': meeting_titles[i],
                'description': f'{meeting_titles[i]} meeting for the team',
                'scheduled_for': scheduled_time,
                'started_at': started_at,
                'ended_at': ended_at,
                'max_participants': random.randint(5, 20),
                'participants': self._generate_meeting_participants(room['participants'], host_id, meeting_state),
                'recording_url': f'https://recordings.example.com/{meeting_titles[i].lower().replace(" ", "_")}.mp4' if meeting_state == 'completed' and random.random() < 0.7 else None
            }
            
            meetings.append(meeting)
        
        self.meetings = meetings
        return meetings
    
    def _generate_message_content(self, room: Dict, sender_id: str) -> str:
        """Generate realistic message content"""
        template = random.choice(self.message_content_templates)
        
        # Find sender name
        sender = next((u for u in self.users if u['id'] == sender_id), None)
        sender_name = sender['display_name'].split()[0] if sender else 'User'
        
        # Find a random participant name for mentions
        other_participants = [p for p in room['participants'] if p != sender_id]
        if other_participants:
            other_user = next((u for u in self.users if u['id'] == random.choice(other_participants)), None)
            other_name = other_user['display_name'].split()[0] if other_user else 'User'
        else:
            other_name = 'everyone'
        
        # Replace placeholders
        content = template.replace('{name}', other_name)
        content = content.replace('{time}', f'{random.randint(9, 17)}:00')
        
        return content
    
    def _determine_message_type(self) -> str:
        """Determine message type with realistic distribution"""
        return random.choices(
            ['text', 'image', 'file', 'audio', 'system'],
            weights=[0.8, 0.1, 0.05, 0.04, 0.01]
        )[0]
    
    def _generate_reactions(self, participant_ids: List[str]) -> List[Dict[str, Any]]:
        """Generate realistic message reactions"""
        reactions = []
        
        # Some messages get reactions (30% chance)
        if random.random() < 0.3:
            reaction_count = random.randint(1, min(3, len(participant_ids)))
            reactors = random.sample(participant_ids, reaction_count)
            
            for reactor_id in reactors:
                reactions.append({
                    'user_id': reactor_id,
                    'emoji': random.choice(self.emojis)
                })
        
        return reactions
    
    def _generate_meeting_participants(self, room_participants: List[str], host_id: str, meeting_state: str) -> List[Dict[str, Any]]:
        """Generate meeting participant data"""
        participants = []
        
        # Host is always a participant
        host_participant = {
            'user_id': host_id,
            'role': 'host',
            'joined_at': None,
            'left_at': None,
            'is_audio_enabled': True,
            'is_video_enabled': True,
            'connection_quality': 'excellent'
        }
        
        if meeting_state != 'upcoming':
            host_participant['joined_at'] = self._random_past_time(hours=1)
            if meeting_state == 'completed':
                host_participant['left_at'] = self._random_past_time(minutes=30)
        
        participants.append(host_participant)
        
        # Add other participants
        other_participants = [p for p in room_participants if p != host_id]
        participant_count = random.randint(1, min(len(other_participants), 5))
        
        for user_id in random.sample(other_participants, participant_count):
            participant = {
                'user_id': user_id,
                'role': 'participant',
                'joined_at': None,
                'left_at': None,
                'is_audio_enabled': random.choice([True, False]),
                'is_video_enabled': random.choice([True, False]),
                'connection_quality': random.choice(['excellent', 'good', 'poor'])
            }
            
            if meeting_state != 'upcoming' and random.random() > 0.2:  # 80% actually join
                participant['joined_at'] = self._random_past_time(hours=1)
                if meeting_state == 'completed':
                    participant['left_at'] = self._random_past_time(minutes=random.randint(5, 90))
            
            participants.append(participant)
        
        return participants
    
    def _generate_meeting_time(self, meeting_state: str) -> datetime:
        """Generate meeting time based on state"""
        if meeting_state == 'upcoming':
            return datetime.now() + timedelta(hours=random.randint(1, 48))
        elif meeting_state == 'active':
            return datetime.now() - timedelta(minutes=random.randint(5, 60))
        else:  # completed
            return self._random_past_time(hours=random.randint(1, 168))
    
    def _random_past_time(self, days: int = 0, hours: int = 0, minutes: int = 0) -> datetime:
        """Generate a random time in the past"""
        total_minutes = days * 24 * 60 + hours * 60 + minutes
        random_minutes = random.randint(0, total_minutes)
        return datetime.now() - timedelta(minutes=random_minutes)
    
    def _random_future_time(self, base_time: datetime, days: int = 0, hours: int = 0, minutes: int = 0) -> datetime:
        """Generate a random time in the future from base_time"""
        total_minutes = days * 24 * 60 + hours * 60 + minutes
        random_minutes = random.randint(0, total_minutes)
        return base_time + timedelta(minutes=random_minutes)
    
    def generate_sql(self, output_file: str = None) -> str:
        """Generate SQL INSERT statements for all data"""
        sql_statements = []
        
        # Clear existing data
        sql_statements.append("-- Clear existing test data")
        sql_statements.append("DELETE FROM message_reactions;")
        sql_statements.append("DELETE FROM message_status;")
        sql_statements.append("DELETE FROM messages;")
        sql_statements.append("DELETE FROM typing_indicators;")
        sql_statements.append("DELETE FROM user_presence;")
        sql_statements.append("DELETE FROM room_participants;")
        sql_statements.append("DELETE FROM rooms;")
        sql_statements.append("DELETE FROM meeting_recordings;")
        sql_statements.append("DELETE FROM meeting_invitations;")
        sql_statements.append("DELETE FROM meeting_participants;")
        sql_statements.append("DELETE FROM meetings;")
        sql_statements.append("DELETE FROM user_profiles;")
        sql_statements.append("")
        
        # Insert users
        sql_statements.append("-- Insert users")
        for user in self.users:
            sql_statements.append(
                f"INSERT INTO user_profiles (id, display_name, avatar_url, phone_number, status_message, is_online, last_seen) "
                f"VALUES ('{user['id']}', '{user['display_name']}', '{user['avatar_url']}', '{user['phone_number']}', "
                f"'{user['status_message']}', {user['is_online']}, '{user['last_seen'].isoformat()}');"
            )
        
        # Insert rooms
        sql_statements.append("\n-- Insert rooms")
        for room in self.rooms:
            name_value = f"'{room['name']}'" if room['name'] else "NULL"
            desc_value = f"'{room['description']}'" if room['description'] else "NULL"
            avatar_value = f"'{room['avatar_url']}'" if room['avatar_url'] else "NULL"
            
            sql_statements.append(
                f"INSERT INTO rooms (id, name, description, type, created_by, avatar_url, last_message_at, created_at) "
                f"VALUES ('{room['id']}', {name_value}, {desc_value}, '{room['type']}', '{room['created_by']}', "
                f"{avatar_value}, '{room['last_message_at'].isoformat()}', '{room['created_at'].isoformat()}');"
            )
            
            # Insert room participants
            for participant_id in room['participants']:
                role = 'admin' if participant_id == room['created_by'] else 'member'
                sql_statements.append(
                    f"INSERT INTO room_participants (room_id, user_id, role, joined_at, is_active) "
                    f"VALUES ('{room['id']}', '{participant_id}', '{role}', '{room['created_at'].isoformat()}', true);"
                )
        
        # Insert messages
        sql_statements.append("\n-- Insert messages")
        for message in self.messages:
            reply_to_value = f"'{message['reply_to']}'" if message['reply_to'] else "NULL"
            edited_at_value = f"'{message['edited_at'].isostring()}'" if message['edited_at'] else "NULL"
            deleted_at_value = f"'{message['deleted_at'].isostring()}'" if message['deleted_at'] else "NULL"
            
            sql_statements.append(
                f"INSERT INTO messages (id, room_id, user_id, content, type, reply_to, created_at, edited_at, deleted_at) "
                f"VALUES ('{message['id']}', '{message['room_id']}', '{message['user_id']}', '{message['content']}', "
                f"'{message['type']}', {reply_to_value}, '{message['created_at'].isoformat()}', {edited_at_value}, {deleted_at_value});"
            )
            
            # Insert reactions
            for reaction in message['reactions']:
                sql_statements.append(
                    f"INSERT INTO message_reactions (message_id, user_id, emoji, created_at) "
                    f"VALUES ('{message['id']}', '{reaction['user_id']}', '{reaction['emoji']}', '{message['created_at'].isoformat()}');"
                )
        
        # Insert meetings
        sql_statements.append("\n-- Insert meetings")
        for meeting in self.meetings:
            started_at_value = f"'{meeting['started_at'].isoformat()}'" if meeting['started_at'] else "NULL"
            ended_at_value = f"'{meeting['ended_at'].isoformat()}'" if meeting['ended_at'] else "NULL"
            recording_value = f"'{meeting['recording_url']}'" if meeting['recording_url'] else "NULL"
            
            sql_statements.append(
                f"INSERT INTO meetings (id, room_id, livekit_room_name, host_id, title, description, scheduled_for, started_at, ended_at, max_participants, recording_url) "
                f"VALUES ('{meeting['id']}', '{meeting['room_id']}', '{meeting['livekit_room_name']}', '{meeting['host_id']}', "
                f"'{meeting['title']}', '{meeting['description']}', '{meeting['scheduled_for'].isoformat()}', {started_at_value}, "
                f"{ended_at_value}, {meeting['max_participants']}, {recording_value});"
            )
            
            # Insert meeting participants
            for participant in meeting['participants']:
                joined_at_value = f"'{participant['joined_at'].isoformat()}'" if participant['joined_at'] else "NULL"
                left_at_value = f"'{participant['left_at'].isoformat()}'" if participant['left_at'] else "NULL"
                
                sql_statements.append(
                    f"INSERT INTO meeting_participants (meeting_id, user_id, role, joined_at, left_at, is_audio_enabled, is_video_enabled, connection_quality) "
                    f"VALUES ('{meeting['id']}', '{participant['user_id']}', '{participant['role']}', {joined_at_value}, {left_at_value}, "
                    f"{participant['is_audio_enabled']}, {participant['is_video_enabled']}, '{participant['connection_quality']}');"
                )
        
        sql_statements.append("\n-- Test data generation completed")
        sql_statements.append("SELECT 'Advanced test data generated successfully!' as status;")
        
        sql_content = '\n'.join(sql_statements)
        
        if output_file:
            with open(output_file, 'w') as f:
                f.write(sql_content)
            print(f"SQL generated and saved to {output_file}")
        
        return sql_content

def main():
    parser = argparse.ArgumentParser(description='Generate comprehensive test data for WhatsApp Clone')
    parser.add_argument('--users', type=int, default=20, help='Number of users to generate')
    parser.add_argument('--messages-per-room', type=int, default=15, help='Average messages per room')
    parser.add_argument('--meetings', type=int, default=8, help='Number of meetings to generate')
    parser.add_argument('--output', type=str, default='supabase/advanced_seed.sql', help='Output SQL file')
    parser.add_argument('--json', type=str, help='Output JSON file for data inspection')
    
    args = parser.parse_args()
    
    print("🎲 Generating advanced test data...")
    
    generator = TestDataGenerator()
    
    # Generate all data
    users = generator.generate_users(args.users)
    rooms = generator.generate_rooms()
    messages = generator.generate_messages(args.messages_per_room)
    meetings = generator.generate_meetings(args.meetings)
    
    print(f"✅ Generated: {len(users)} users, {len(rooms)} rooms, {len(messages)} messages, {len(meetings)} meetings")
    
    # Output SQL
    sql_content = generator.generate_sql(args.output)
    
    # Output JSON if requested
    if args.json:
        data = {
            'users': users,
            'rooms': rooms,
            'messages': messages,
            'meetings': meetings,
            'generated_at': datetime.now().isoformat()
        }
        
        # Convert datetime objects to strings for JSON serialization
        def serialize_datetime(obj):
            if isinstance(obj, datetime):
                return obj.isoformat()
            raise TypeError(f"Object of type {type(obj)} is not JSON serializable")
        
        with open(args.json, 'w') as f:
            json.dump(data, f, indent=2, default=serialize_datetime)
        
        print(f"📊 JSON data saved to {args.json}")
    
    print("🎉 Test data generation completed!")

if __name__ == '__main__':
    main()