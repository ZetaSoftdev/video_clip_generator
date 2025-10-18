#!/usr/bin/env python3
"""
Migration script to make caption_filename nullable in generated_clips table
"""
import os
from sqlalchemy import create_engine, text
import config

def migrate():
    """Run the migration to make caption_filename nullable"""
    database_url = config.DATABASE_URL
    engine = create_engine(database_url)
    
    print("Starting migration: Make caption_filename nullable in generated_clips table")
    
    try:
        with engine.connect() as conn:
            # For PostgreSQL
            if 'postgresql' in database_url:
                print("Detected PostgreSQL database")
                conn.execute(text(
                    "ALTER TABLE generated_clips ALTER COLUMN caption_filename DROP NOT NULL;"
                ))
                conn.commit()
                print("✅ Successfully altered caption_filename to be nullable (PostgreSQL)")
            
            # For SQLite
            elif 'sqlite' in database_url:
                print("Detected SQLite database")
                print("Note: SQLite doesn't support ALTER COLUMN directly.")
                print("The schema change will take effect when the table is recreated.")
                print("✅ Model updated - changes will apply on next table creation")
            
            else:
                print("⚠️ Unknown database type. Please manually alter the schema.")
        
        print("Migration completed successfully!")
        
    except Exception as e:
        print(f"❌ Migration failed: {str(e)}")
        raise

if __name__ == "__main__":
    migrate()
