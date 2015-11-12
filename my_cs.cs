using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;

namespace Program_IDEA
{
    public partial class frmMain : Form
    {   
        byte[] keys = new byte[16];
        UInt16[][] sub_Keys = new UInt16[9][];

        byte[] block_of_Data = new byte[8];
        UInt16 [] sub_Block_of_Data= new UInt16[4];


        public frmMain()
        {
            InitializeComponent();
            for (int i = 0; i < 8; i++)
                sub_Keys[i] = new UInt16[6];
            sub_Keys[8] = new UInt16[4];
            btnEncrypt.Enabled = false;
            btnDecrypt.Enabled = false;
        }


        


        

        

        public void cycle_shl_25_Positions(ref byte[] keys)
        {
            byte[] temp_Key = new byte[4];
            int length_keys = keys.Length;
            for(int i = 0; i < temp_Key.Length; i++)
            {
                temp_Key[i] = keys[length_keys - 1 - i];
            }

            for (int i = keys.Length - 1; i >= 4; i--)
                keys[i] = (byte)(((keys[i - 3] & 127) << 1) + ((keys[i - 4] & 128) >> 7));

            keys[3] = (byte)(((keys[0] & 127) << 1) + ((temp_Key[0] & 128) >> 7));

            for (int i = 0; i <= 2; i++)
            {
                keys[2 - i] = (byte)(((temp_Key[i] & 127) << 1) + ((temp_Key[i + 1] & 128) >> 7));
            }

        }

        public void Generate_Subs_Keys(ref byte[] keys, ref UInt16[][] sub_Keys)
        { 

            for(int i = 0; i < 6; i++)
            {
                for(int j = 0; j < 8; j++)
                {
                    sub_Keys[(i*8 + j) / 6][(i * 8 + j) % 6] = (UInt16)((keys[15 - 2*j] << 8) + keys[15 - 2*j - 1]);
                }
                cycle_shl_25_Positions(ref keys);                
            }
            for(int i = 0; i < 4; i++)
                sub_Keys[8][i] = (UInt16)((keys[15 - 2*i] << 8) + keys[15 - 2*i - 1]);

        }

        public int read_Keys_from_File(string file_Name, ref byte[] keys)
        {
            using (FileStream fstream = File.OpenRead(file_Name))
            {
                if (fstream.Length >= 15)
                {
                    for (int i = 15; i >= 0; i--)
                        keys[i] = (Byte)fstream.ReadByte();
                    return 1;
                }
                else
                    return 0;
                
            }
        }

        public int init_Keys_from_File(string key_File_Name)
        {
            if (read_Keys_from_File(key_File_Name, ref keys) == 1)
            {
                Generate_Subs_Keys(ref keys, ref sub_Keys);
                return 1;
            }
            else
                return 0;
            
        }

        private void siOpenFileOfKey_Click(object sender, EventArgs e)
        {
            string key_File_Name;
            if (dlgOpenFile.ShowDialog() == DialogResult.OK)
            {
                key_File_Name = dlgOpenFile.FileName;
                if (init_Keys_from_File(key_File_Name) == 1)
                {
                    edtLocationOfKey.Text = key_File_Name;       
                }
                else
                    MessageBox.Show("Incorrect FILE");      

            }
            if ((edtLocationOfData.Text.Length != 0) && (edtLocationOfKey.Text.Length != 0))
            {
                btnEncrypt.Enabled = true;
                btnDecrypt.Enabled = true;
            }
            else
            {
                btnEncrypt.Enabled = false;
                btnDecrypt.Enabled = false;
            }
                

        }




        public UInt16 multiplication(UInt16 A, UInt16 B)
        {
            UInt64 temp_A, temp_B;
            if (A == 0)
                temp_A = 65536;
            else
                temp_A = A;
            if (B == 0)
                temp_B = 65536;
            else
                temp_B = B;
            return (UInt16)((temp_A * temp_B) % 65537);
        }

        public UInt16 addition(UInt16 A, UInt16 B)
        {
            return (UInt16)((A + B) % 65536);
        }

        public UInt16 xor(UInt16 A, UInt16 B)
        {
            return (UInt16)(A ^ B);
        }


        public void round_1_8_of_Encrypt(ref UInt16[] sub_Block_of_Data, ref UInt16[][] sub_Keys, int index)
        {
            UInt16 A, B, C, D, E, F;
            A = multiplication(sub_Block_of_Data[0], sub_Keys[index][0]);
            B = addition(sub_Block_of_Data[1], sub_Keys[index][1]);
            C = addition(sub_Block_of_Data[2], sub_Keys[index][2]);
            D = multiplication(sub_Block_of_Data[3], sub_Keys[index][3]);
            E = xor(A, C);
            F = xor(B, D);
            sub_Block_of_Data[0] = xor(A, multiplication(addition(F, multiplication(E, sub_Keys[index][4])), sub_Keys[index][5]));
            sub_Block_of_Data[1] = xor(C, multiplication(addition(F, multiplication(E, sub_Keys[index][4])), sub_Keys[index][5]));
            sub_Block_of_Data[2] = xor(B, addition(multiplication(E, sub_Keys[index][4]), multiplication(addition(F, multiplication(E, sub_Keys[index][4])), sub_Keys[index][5])));
            sub_Block_of_Data[3] = xor(D, addition(multiplication(E, sub_Keys[index][4]), multiplication(addition(F, multiplication(E, sub_Keys[index][4])), sub_Keys[index][5])));
        }

        public void round_9_of_Encrypt(ref UInt16[] sub_Block_of_Data, ref UInt16[][] sub_Keys)
        {
            byte index = 8;
            UInt16 temp_Sub_Block_2 = sub_Block_of_Data[1];
            sub_Block_of_Data[0] = multiplication(sub_Block_of_Data[0], sub_Keys[index][0]);
            sub_Block_of_Data[1] = addition(sub_Block_of_Data[2], sub_Keys[index][1]);
            sub_Block_of_Data[2] = addition(temp_Sub_Block_2, sub_Keys[index][2]);
            sub_Block_of_Data[3] = multiplication(sub_Block_of_Data[3], sub_Keys[index][3]);
        }

        public void init_current_values_of_Sub_Blocks_of_Data(ref UInt16[] sub_Block_of_Data, ref byte[] block_of_Data)
        {
            for (int i = 0; i < 4; i++)
                sub_Block_of_Data[i] = (UInt16)((block_of_Data[2 * i] << 8) + block_of_Data[2 * i + 1]);
        }

        public void init_current_values_of_Blocks_Of_Data(ref UInt16[] sub_Block_of_Data, ref byte[] block_of_Data)
        {
            for(int i = 0; i < 4; i++)
            {
                block_of_Data[2 * i] = (byte)(sub_Block_of_Data[i] >> 8);
                block_of_Data[2 * i + 1] = (byte)(sub_Block_of_Data[i]);
            }
        }

        public void work_with_Data(string data_File_Name, char method)
        {
            using (FileStream fstream = new FileStream(data_File_Name, FileMode.Open))
            {
                long file_length = 0;
                int current_place_in_File = 0;
                int count_of_read_bytes;
                bool additional_nulls = false;
                byte byte_of_count_additional_nulls = 0;

                switch (method)
                {
                    case 'E':
                        init_Keys_from_File(edtLocationOfKey.Text);
                        if ((fstream.Length % 8) == 0)
                            file_length = fstream.Length / 8;
                        else
                            file_length = (fstream.Length / 8) + 1;
                        break;
                    case 'D':
                        init_Keys_from_File(edtLocationOfKey.Text);
                        change_keys_to_decrypt(ref sub_Keys);
                        if (((fstream.Length) % 8) != 0)                         
                            additional_nulls = true;
                        file_length = fstream.Length / 8;
                        break;
                }              

                for(long scorer = 0; scorer < file_length; scorer++)
                {
                    fstream.Seek(current_place_in_File, SeekOrigin.Begin);
                    count_of_read_bytes = fstream.Read(block_of_Data, 0, 8);

                    if (count_of_read_bytes == 8)
                    {
                        init_current_values_of_Sub_Blocks_of_Data(ref sub_Block_of_Data, ref block_of_Data);

                    }
                    else
                    {
                        additional_nulls = true;
                        for (int i = count_of_read_bytes; i < 8; i++)
                            block_of_Data[i] = 0;
                        init_current_values_of_Sub_Blocks_of_Data(ref sub_Block_of_Data, ref block_of_Data);
                    }

                    encrypt(ref sub_Block_of_Data, ref sub_Keys);

                    if (additional_nulls && (scorer == file_length - 1))
                    {
                        switch (method)
                        {
                            case 'E':
                                byte_of_count_additional_nulls = (byte)(8 - count_of_read_bytes);
                                fstream.Seek(byte_of_count_additional_nulls, SeekOrigin.Current);
                                count_of_read_bytes += byte_of_count_additional_nulls;
                                fstream.WriteByte(byte_of_count_additional_nulls);
                                byte_of_count_additional_nulls = 0;
                                break;
                            case 'D':
                                byte_of_count_additional_nulls = (byte)fstream.ReadByte();
                                fstream.SetLength(file_length * 8 - byte_of_count_additional_nulls);
                                fstream.Seek(current_place_in_File + 8 + 1, SeekOrigin.Begin);                             
                                break;
                        }
                        count_of_read_bytes++;    
                    }

                    fstream.Seek(-(count_of_read_bytes), SeekOrigin.Current);
                    init_current_values_of_Blocks_Of_Data(ref sub_Block_of_Data, ref block_of_Data);

                    fstream.Write(block_of_Data, 0, 8 - byte_of_count_additional_nulls);
                    current_place_in_File += count_of_read_bytes;
                    
                }
            }







            



            
            
            
            
                
              
        }

        private void siOpenFileOfData_Click(object sender, EventArgs e)
        {
            string data_File_Name;
            if (dlgOpenFile.ShowDialog() == DialogResult.OK)
            {
                data_File_Name = dlgOpenFile.FileName;
                edtLocationOfData.Text = data_File_Name;
            }
            if ((edtLocationOfData.Text.Length != 0) && (edtLocationOfKey.Text.Length != 0))
            {
                btnEncrypt.Enabled = true;
                btnDecrypt.Enabled = true;
            }
            else
            {
                btnEncrypt.Enabled = false;
                btnDecrypt.Enabled = false;
            }
        }


        public void change_keys_to_decrypt(ref UInt16[][] sub_Keys)
        {
            UInt16 temp_Key_1, temp_Key_2;
            for(int i = 0; i < 4; i++)
            {
                temp_Key_1 = sub_Keys[i][0];
                temp_Key_2 = sub_Keys[i][3];
                sub_Keys[i][0] = multiplicative_inversion(sub_Keys[8 - i][0]);
                sub_Keys[i][3] = multiplicative_inversion(sub_Keys[8 - i][3]);
                sub_Keys[8 - i][0] = multiplicative_inversion(temp_Key_1);
                sub_Keys[8 - i][3] = multiplicative_inversion(temp_Key_2);
            }
            sub_Keys[4][0] = multiplicative_inversion(sub_Keys[4][0]);
            sub_Keys[4][3] = multiplicative_inversion(sub_Keys[4][3]);

            temp_Key_1 = sub_Keys[8][1];
            temp_Key_2 = sub_Keys[8][2];
            sub_Keys[8][1] = additive_inversion(sub_Keys[0][1]);
            sub_Keys[8][2] = additive_inversion(sub_Keys[0][2]);
            sub_Keys[0][1] = additive_inversion(temp_Key_1);
            sub_Keys[0][2] = additive_inversion(temp_Key_2);

            for(int i = 1; i < 5; i++)
            {
                temp_Key_1 = sub_Keys[i][1];
                temp_Key_2 = sub_Keys[i][2];
                sub_Keys[i][1] = additive_inversion(sub_Keys[8 - i][2]);
                sub_Keys[i][2] = additive_inversion(sub_Keys[8 - i][1]);
                sub_Keys[8 - i][1] = additive_inversion(temp_Key_2);
                sub_Keys[8 - i][2] = additive_inversion(temp_Key_1);
            }

            for(int i = 0; i < 4; i++)
            {
                temp_Key_1 = sub_Keys[i][4];
                temp_Key_2 = sub_Keys[i][5];
                sub_Keys[i][4] = sub_Keys[7 - i][4];
                sub_Keys[i][5] = sub_Keys[7 - i][5];
                sub_Keys[7 - i][4] = temp_Key_1;
                sub_Keys[7 - i][5] = temp_Key_2;
            }
        }

        public UInt16 binpow(UInt16 a, UInt16 n)
        {
            UInt16 res = 1;
            while (n != 0)
            {
                if ((n & 1) != 0)
                    res = multiplication(res, a);
                a = multiplication(a, a);
                n >>= 1;
            }
            return (UInt16)res;
        }

        public UInt16 multiplicative_inversion(UInt16 A)
        {
            return binpow(A, 65535);
        }

        public UInt16 additive_inversion(UInt16 A)
        {
            return (UInt16)(65536 - A);
        }

        public void encrypt(ref UInt16[] sub_Block_of_Data, ref UInt16[][] sub_Keys)
        {

            for (byte index = 0; index < 8; index++)
            {
                round_1_8_of_Encrypt(ref sub_Block_of_Data, ref sub_Keys, index);
            }
            round_9_of_Encrypt(ref sub_Block_of_Data, ref sub_Keys);
        }

        private void btnEncrypt_Click(object sender, EventArgs e)
        {

            work_with_Data(edtLocationOfData.Text, 'E');
            MessageBox.Show("Шифрование успешно выполнено");
        }

        private void btnDecrypt_Click(object sender, EventArgs e)
        {
            work_with_Data(edtLocationOfData.Text, 'D');
            MessageBox.Show("Расшифровка успешна выполнена");
        }
    }

   
}
