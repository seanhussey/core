module Gluttonberg
  module Library
    module DefaultAssetTypes
      def self.build
        self.build_unknown_types
        self.build_image_types
        self.build_audio_types
        self.build_video_types
        self.build_document_types
      end

      # Makes sure the specified type exists in the DB, if it doesn’t it creates
      # a new record.
      def self.ensure_type(name, mime_type, category)
        asset_type = AssetType.where(:name => name).first
        if asset_type then
          asset_type.asset_category = category
        else
          asset_type = AssetType.new(:name => name, :asset_category => category)
        end
        mime_type.split(' ').each do |this_mime_type|
          asset_mime_type = AssetMimeType.new(:mime_type => this_mime_type)
          asset_type.asset_mime_types << asset_mime_type
          asset_mime_type.save
        end
        asset_type.save
      end

      private
        def self.build_unknown_types
          ensure_type('Unknown Image', 'image', AssetCategory.image_category)
          ensure_type('Unknown Video', 'video', AssetCategory.video_category)
          ensure_type('Unknown Audio', 'audio', AssetCategory.audio_category)
          ensure_type('Unknown File',   'multi-part model message unknown', AssetCategory.uncategorised_category)
        end

        def self.build_image_types
          ensure_type('Jpeg Image', 'image/jpeg image/pjpeg', AssetCategory.image_category)
          ensure_type('Gif Image', 'image/gif', AssetCategory.image_category)
          ensure_type('Png Image', 'image/png', AssetCategory.image_category)
          ensure_type('Tiff Image', 'image/tiff', AssetCategory.image_category)
          ensure_type('Adobe Photoshop Image', 'image/vnd.adobe.photoshop', AssetCategory.image_category)
          ensure_type('Autocad Image', 'image/vnd.dwg', AssetCategory.image_category)
          ensure_type('Autocad Image', 'image/vnd.dxf', AssetCategory.image_category)
          ensure_type('Icon Image', 'image/vnd.microsoft.icon', AssetCategory.image_category)
          ensure_type('Bitmap Image', 'image/x-bmp image/bmp image/x-win-bmp', AssetCategory.image_category)
          ensure_type('Paintshop Pro Image', 'image/x-paintshoppro', AssetCategory.image_category)
          ensure_type('Mobile Image (plb,psb,pvb)', 'application/vnd.3gpp.pic-bw-large application/vnd.3gpp.pic-bw-small application/vnd.3gpp.pic-bw-var', AssetCategory.image_category)
        end

        def self.build_audio_types
          ensure_type('Moile Audio (3gpp,3gpp2)', 'audio/3gpp audio/3gpp2', AssetCategory.audio_category)
          ensure_type('Dolby Digital Audio (ac3)', 'audio/ac3', AssetCategory.audio_category)
          ensure_type('Mpeg Audio (mpga,mp2,mp3,mp4,mpa)', 'audio/mpeg audio/mpeg4-generic audio/mp4 audio/mp3 audio/mpa-robust', AssetCategory.audio_category) # @mpga,mp2,mp3
          ensure_type('Aiff Audio (aif,aifc,aiff)', 'audio/x-aiff', AssetCategory.audio_category)
          ensure_type('Midi Audio (mid,midi,kar)', 'audio/x-midi', AssetCategory.audio_category)
          ensure_type('Real Audio (rm,ram,ra)', 'audio/x-pn-realaudio audio/x-realaudio', AssetCategory.audio_category)
          ensure_type('Wav Audio (wav)', 'audio/x-wav', AssetCategory.audio_category)
          ensure_type('Ogg Vorbis Audio (ogg)', 'application/ogg', AssetCategory.audio_category)
        end

        def self.build_video_types
          ensure_type('Mobile Video', 'video/3gpp video/3gpp-tt video/3gpp2', AssetCategory.video_category) #  @3gp,3gpp 'RFC3839,DRAFT:draft-gellens-mime-bucket
          ensure_type('Digital Video', 'video/DV', AssetCategory.video_category) #  RFC3189
          ensure_type('Compressed Video', 'application/mpeg4-iod-xmt application/mpeg4-iod application/mpeg4-generic video/mp4  application/mp4 video/MPV video/mpeg4-generic video/mpeg video/MP2T video/H261 video/H263 video/H263-1998 video/H263-2000 video/H264 video/MP1S video/MP2P', AssetCategory.video_category) #  RFC3555
          ensure_type('Jpeg Video', 'video/JPEG video/MJ2', AssetCategory.video_category) #  RFC3555
          ensure_type('Quicktime Video', 'video/quicktime', AssetCategory.video_category)
          ensure_type('Uncompressed Video', 'video/raw', AssetCategory.video_category)
          ensure_type('Mpeg Playlist (mxu,m4u)', 'video/vnd.mpegurl', AssetCategory.video_category)
          ensure_type('Avi Video (avi)', 'video/x-msvideo', AssetCategory.video_category)
          ensure_type('Flash Video', 'video/x-flv', AssetCategory.video_category)
          ensure_type('M4v Video', 'video/x-m4v', AssetCategory.video_category)
        end

        def self.build_document_types
          #document category
          ensure_type('Generic Document', 'application/x-csh application/x-dvi application/oda application/pgp-encrypted application/pgp-keys application/pgp-signature', AssetCategory.document_category)
          ensure_type('Calendar Document', 'text/calendar text/x-vcalendar', AssetCategory.document_category)
          ensure_type('Comma Seperated Values Document (csv)', 'text/csv text/comma-separated-values', AssetCategory.document_category)
          ensure_type('Tab Seperated Values Text Document', 'text/tab-separated-values', AssetCategory.document_category)
          ensure_type('Web Document', 'text/html', AssetCategory.document_category)
          ensure_type('Plain Text Document', 'text/plain', AssetCategory.document_category)
          ensure_type('Rich Text Document', 'text/richtext text/rtf', AssetCategory.document_category)
          ensure_type('Sgml Document', 'text/sgml', AssetCategory.document_category)
          ensure_type('Wap Document', 'text/vnd.wap.wml text/vnd.wap.wmlscript', AssetCategory.document_category)
          ensure_type('XML Document', 'text/xml text/xml-external-parsed-entity', AssetCategory.document_category)
          ensure_type('V-Card Document (vcf)', 'text/x-vcard', AssetCategory.document_category)
          ensure_type('Apple Macintosh Document (hqx)', 'application/mac-binhex40', AssetCategory.document_category)
          ensure_type('Adobe Acrobat Document (pdf)', 'application/pdf', AssetCategory.document_category)
          self.buid_microsoft_office_types
        end

        def self.buid_microsoft_office_types
          ensure_type('Microsoft Word Document (doc,dot,docx)', 'application/msword application/word', AssetCategory.document_category)
          ensure_type('Microsoft Powerpoint Document (ppt,pps,pot,pptx)', 'application/vnd.ms-powerpoint application/powerpoint', AssetCategory.document_category)
          ensure_type('Microsoft Excel Document (xls,xlt,xlsx)', 'application/vnd.ms-excel application/excel', AssetCategory.document_category)
          ensure_type('Microsoft Works Document', 'application/vnd.ms-works', AssetCategory.document_category)
          ensure_type('Microsoft Project Document (mpp)', 'application/vnd.ms-project', AssetCategory.document_category)
          ensure_type('Microsoft Visio Document (vsd,vst,vsw,vss)', 'application/vnd.visio', AssetCategory.document_category)
          ensure_type('HTML Help Document (chm)', 'application/x-chm', AssetCategory.document_category)
        end
    end
  end
end