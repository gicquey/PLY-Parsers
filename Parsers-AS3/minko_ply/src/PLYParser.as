/**
 * Created by Youri GICQUEL
 */
package {
import aerys.minko.render.geometry.Geometry;
import aerys.minko.render.geometry.GeometrySanitizer;
import aerys.minko.render.geometry.stream.IVertexStream;
import aerys.minko.render.geometry.stream.IndexStream;
import aerys.minko.render.geometry.stream.StreamUsage;
import aerys.minko.render.geometry.stream.VertexStream;
import aerys.minko.render.geometry.stream.format.VertexComponent;
import aerys.minko.render.geometry.stream.format.VertexFormat;
import aerys.minko.render.material.Material;
import aerys.minko.render.material.basic.BasicMaterial;
import aerys.minko.render.material.phong.PhongEffect;
import aerys.minko.scene.node.Group;
import aerys.minko.scene.node.Mesh;
import aerys.minko.type.enum.TriangleCulling;

import flash.geom.Vector3D;

import flash.utils.ByteArray;
import flash.utils.Endian;

public class PLYParser {
    
    private var vertex:Vector.<Number> = new <Number>[];
    private var _verts:int;
    private var _faces:int;
    private var _final_index:Vector.<uint> = new <uint>[];
    private var _indexT:Vector.<uint> = new <uint>[];
    private var _indexQ:Vector.<uint> = new <uint>[];
    private var _vertexQ:Vector.<Number> = new <Number>[];
    private var _vertexT:Vector.<Number> = new <Number>[];
    private var _normalStream:Vector.<Number> = new <Number>[];

    private var __indexTri:ByteArray = new ByteArray();
    private var __indexQuad:ByteArray = new ByteArray();
    private var __vertexTri:ByteArray = new ByteArray();
    private var __vertexQuad:ByteArray = new ByteArray();

    private var _p1:Vector3D = new Vector3D();
    private var _p2:Vector3D = new Vector3D();
    private var _p3:Vector3D = new Vector3D();

    private var _normal:Vector3D = new Vector3D();
    private var _r:Number;
    private var _g:Number;
    private var _b:Number;

    public var color:Vector.<Number> = new <Number>[];
    private var normals:Boolean;
    private var colors:Boolean;


    private function generate_normalStream():void {
        var i:int = 0;
        var pos:int = 0;
        var cpt:int = 0;
        var tmp:Vector.<Number> = new <Number>[];
        var tm_p2:Vector.<uint> = new <uint>[];

        while (i < _final_index.length){
            pos = _final_index[i] * 3;
            _p1.x = vertex[pos];
            _p1.y = vertex[pos + 1];
            _p1.z = vertex[pos + 2];
            i++;
            pos = _final_index[i] * 3;
            _p2.x = vertex[pos];
            _p2.y = vertex[pos + 1];
            _p2.z = vertex[pos + 2];
            i++;
            pos = _final_index[i] * 3;
            _p3.x = vertex[pos];
            _p3.y = vertex[pos + 1];
            _p3.z = vertex[pos + 2];
            i++;
            _normal.x = (_p2.x - _p1.x) * (_p3.z - _p1.z) - (_p2.z - _p1.z) * (_p3.y - _p1.y);
            _normal.y = (_p2.z - _p1.z) * (_p3.x - _p1.x) - (_p2.x - _p1.x) * (_p3.z - _p1.z);
            _normal.z = (_p2.x - _p1.x) * (_p3.y - _p1.y) - (_p2.y - _p1.y) * (_p3.x - _p1.x);
            tmp.push(_p1.x, _p1.y, _p1.z);
            tmp.push(_normal.x, _normal.y, _normal.z);
            tmp.push(_p2.x, _p2.y, _p2.z);
            tmp.push(_normal.x, _normal.y, _normal.z);
            tmp.push(_p3.x, _p3.y, _p3.z);
            tmp.push(_normal.x, _normal.y, _normal.z);
            tm_p2.push(cpt);
            cpt++;
            tm_p2.push(cpt);
            cpt++;
            tm_p2.push(cpt);
            cpt++;
        }
        _vertexT = tmp;
        _final_index = tm_p2;
    }

    private function newVertices(pos:int, tab:ByteArray):void {
        var tmp:String;
        var i:int;

        i = pos;
        while (String(tab).charAt(i) != '\n')
            i++;
        pos += 15;
        tmp = String(tab).slice(pos, i);
        _verts = parseInt(tmp);
    }

    private function newFaces(pos:int, tab:ByteArray):void {
        var tmp:String;
        var i:int;

        i = pos;
        while (String(tab).charAt(i) != '\n')
            i++;
        pos += 13;
        tmp = String(tab).slice(pos, i);
        _faces = parseInt(tmp);
    }

    private function checkContent(tab:ByteArray):void {
        if (String(tab).indexOf("property float _normal.x") > 0)
            normals = true;
        if (String(tab).indexOf("property uchar red") > 0)
            colors = true;
    }

    private function BinaddVertices(tab:ByteArray, val:int):void {
        if (val == 1){
            _p1.x = tab.readFloat();
            _p1.y = tab.readFloat();
            _p1.z = tab.readFloat();
        }
    }

    private function BinaddFace(tab:ByteArray):void{
        var tmp:int;
        tab.readByte();
        tmp = tab.readInt();
        __indexTri.writeInt(tmp);
        tmp = tab.readInt();
        __indexTri.writeInt(tmp);
        tmp = tab.readInt();
        __indexTri.writeInt(tmp);
    }

    private function Binadd_normalStream(tab:ByteArray):ByteArray {
        _normal.x = tab.readFloat();
        _normal.y = tab.readFloat();
        _normal.z = tab.readFloat();
        return (tab);
    }

    private function BinaddColor(tab:ByteArray):ByteArray {
        _r = tab.readFloat();
        _g = tab.readFloat();
        _b = tab.readFloat();
        return (tab);
    }

    private function Binexist():void {
        vertex.push(_p1.x);
        vertex.push(_p1.y);
        vertex.push(_p1.z);
        if (colors){
            vertex.push(_r);
            vertex.push(_g);
            vertex.push(_b);
        }
        if (_normalStream == true){
            vertex.push(_normal.x);
            vertex.push(_normal.y);
            vertex.push(_normal.z);
        }
    }

    private function dupliVert():void {
        var i:int;

        i = 0;
        while (i < vertex.length) {
            __vertexQuad.writeFloat(vertex[i]);
            __vertexTri.writeFloat(vertex[i]);
            i++;
        }
        __vertexQuad.position = 0;
        __vertexTri.position = 0;
    }

    private function toNum():void {

        __vertexQuad.position = 0;
        __vertexTri.position = 0;
        __indexTri.position = 0;
        __indexQuad.position = 0;

        while (__indexQuad.bytesAvailable > 0) {
            _indexQ.push(__indexQuad.readInt());
        }
        while (__indexTri.bytesAvailable > 0) {
            _indexT.push(__indexTri.readInt());
        }
        while (__vertexQuad.bytesAvailable > 0) {
            _vertexQ.push(__vertexQuad.readFloat());
        }
        while (__vertexTri.bytesAvailable > 0) {
            _vertexT.push(__vertexTri.readFloat());
        }
    }

    private function creaFace(tmp:Vector.<uint>):void {
        _final_index.push(tmp[0]);
        _final_index.push(tmp[1]);
        _final_index.push(tmp[2]);
        _final_index.push(tmp[3]);
        _final_index.push(tmp[0]);
        _final_index.push(tmp[2]);
    }

    private function splitQuad():void {
        var i:int;
        var pos:int;
        var tmp:Vector.<uint> = new <uint>[];

        i = 0;
        pos = i;
        while (i < _indexQ.length) {
            if ((i % 4) == 0 && i > 0) {
                tmp = _indexQ.slice(pos, i);
                creaFace(tmp);
                pos = i;
            }
            i++;
        }
        tmp = _indexQ.slice(pos, i);
        if (_indexQ.length > 0)
            creaFace(tmp);
    }

    private function addTriangles():void {
        var i:int;

        i = 0;
        while (i < _indexT.length) {
            _final_index.push(_indexT[i]);
            i++;
        }
    }

    private function Binextract(tab:ByteArray):void {
        var pos:int;
        var i:int = 0;

        pos = String(tab).indexOf("end_header");
        while (String(tab).charAt(pos) != '\n' && pos < tab.length)
            pos++;
        pos++;
        tab.position = pos;
        while (i < _verts) {
            BinaddVertices(tab, 1);
            if (normals == true)
                Binadd_normalStream(tab);
            if (colors == true)
                BinaddColor(tab);
            Binexist();
            i++;
        }
        i = 0;
        while (i < _faces){
            BinaddFace(tab);
            i++;
        }
        __indexQuad.position = 0;
        dupliVert();
    }

    private function PLYType(tab:ByteArray):void {
        if (String(tab).indexOf("big") > 0)
            tab.endian = Endian.BIG_ENDIAN;
        else
            tab.endian = Endian.LITTLE_ENDIAN;
    }

    public function parsing(tab:ByteArray):Group {
        __vertexQuad.position = 0;
        __vertexTri.position = 0;
        __indexTri.position = 0;
        __indexQuad.position = 0;

        PLYType(tab);
        checkContent(tab);
        newVertices(String(tab).indexOf("element vertex "), tab);
        newFaces(String(tab).indexOf("element face "), tab);
        Binextract(tab);
        toNum();
        if (_vertexQ.length > 0)
            splitQuad();
        addTriangles();
        GeometrySanitizer.removeDuplicatedVertices(__vertexTri, __indexTri, 12);
        GeometrySanitizer.removeDuplicatedVertices(__vertexQuad, __indexQuad, 12);
        generate_normalStream();
        return (generateMesh());
    }

    private function generateMesh():Group {
        var group:Group = new Group();

        var mesh:Mesh;
        var geom:Geometry;
        var material:Material;

        // générer l'indexStream
        var indexStream:IndexStream = IndexStream.fromVector(StreamUsage.DYNAMIC, _final_index);

        var verticesStream:Vector.<IVertexStream> = new <IVertexStream>[];

        // générer le vertex buffer
        var format:VertexFormat = new VertexFormat();
        format.addComponent(VertexComponent.XYZ);
        //if (_normalStream == true)
            format.addComponent(VertexComponent.NORMAL);
        if (color == true)
            format.addComponent(VertexComponent.RGB);

        // ajout des composants format
        var vertexStream:VertexStream = VertexStream.fromVector(StreamUsage.DYNAMIC, format, _vertexT);
        verticesStream.push(vertexStream);

        geom = new Geometry(verticesStream, indexStream);
        material = new BasicMaterial(
                {diffuseColor: 0xEEEEEEFF,
                    triangleCulling: TriangleCulling.NONE},
                new PhongEffect()
        );
        mesh = new Mesh(geom, material);

        group.addChild(mesh);
        return group;
    }

    public function PLYParser() {
    }
}
}
